# 1. Grupo de Recursos
resource "azurerm_resource_group" "rg" {
  name     = "RG-Laboratorio20-v3"
  location = "centralus"
}

# 2. Azure Container Registry (Nombre global único)
resource "azurerm_container_registry" "acr" {
  name                = "acrcarlos69v3"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# 3. Azure Kubernetes Service (AKS)
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-lab-v3"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "akscarlosv3"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2ps_v2" # Manteniendo ARM64
  }

  identity {
    type = "SystemAssigned"
  }
}

# 4. Azure SQL Server
resource "azurerm_mssql_server" "sqlserver" {
  name                         = "sqlserver-carlos-v3"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "Password1234!" 
}

# 5. Base de Datos SQL
resource "azurerm_mssql_database" "db" {
  name      = "ticketsdb-v3"
  server_id = azurerm_mssql_server.sqlserver.id
  sku_name  = "S0"
}

# 6. Regla de Firewall para Servicios de Azure
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# --- CONFIGURACIÓN DE HELM ---
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
  depends_on       = [azurerm_kubernetes_cluster.aks]
}