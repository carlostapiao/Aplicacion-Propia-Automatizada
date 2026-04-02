# =============================================================================
# 1. CONFIGURACIÓN DE TERRAFORM Y BACKEND
# =============================================================================
# =============================================================================
# 4. CONFIGURACIÓN DE HELM (CORREGIDA PARA CI/CD)
# =============================================================================

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  }
}

# Asegúrate de que el recurso helm_release tenga el depends_on
resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-basic"
  create_namespace = true
  
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-dns-label-name"
    value = "lab-carlos-tickets-v4" 
  }

  # ESTO ES VITAL: Helm no se ejecutará hasta que el AKS esté 100% creado
  depends_on = [azurerm_kubernetes_cluster.aks]
}

# =============================================================================
# 2. INFRAESTRUCTURA BASE v4
# =============================================================================

resource "azurerm_resource_group" "rg" {
  name     = "RG-Laboratorio20-v4"
  location = "centralus"
}

resource "azurerm_container_registry" "acr" {
  name                = "acrcarlos69v4"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-lab-v4"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "akscarlosv4"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2ps_v2" 
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "aks_to_acr" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

# =============================================================================
# 3. BASE DE DATOS SQL v4
# =============================================================================

resource "azurerm_mssql_server" "sqlserver" {
  name                         = "sqlserver-carlos-v4"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "Password1234!" 
}

resource "azurerm_mssql_database" "db" {
  name      = "ticketsdb-v4"
  server_id = azurerm_mssql_server.sqlserver.id
  sku_name  = "S0"
}

resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# =============================================================================
# 4. HELM E INGRESS CON DNS v4
# =============================================================================

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  }
}

resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-basic"
  create_namespace = true
  
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-dns-label-name"
    value = "lab-carlos-tickets-v4" 
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# =============================================================================
# 5. API MANAGEMENT (APIM) v4
# =============================================================================

resource "azurerm_api_management" "apim" {
  name                = "apim-carlos-lab-v4"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "Carlos Lab"
  publisher_email     = "admin@carloslab.com"
  sku_name            = "Consumption_0"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_api_management_api" "ticket_api" {
  name                = "tickets-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Tickets Support API"
  path                = "" 
  protocols           = ["http", "https"]
  service_url         = "http://lab-carlos-tickets-v4.centralus.cloudapp.azure.com"
}

resource "azurerm_api_management_api_operation" "get_tickets" {
  operation_id        = "get-tickets"
  api_name            = azurerm_api_management_api.ticket_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Listar Tickets"
  method              = "GET"
  url_template        = "/tickets"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "post_ticket" {
  operation_id        = "create-ticket"
  api_name            = azurerm_api_management_api.ticket_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Crear Ticket"
  method              = "POST"
  url_template        = "/tickets"

  response {
    status_code = 201
  }
}

# =============================================================================
# 6. OUTPUTS
# =============================================================================

output "ingress_dns_url" {
  value = "http://lab-carlos-tickets-v4.centralus.cloudapp.azure.com"
}

// Actualización forzada v4.1