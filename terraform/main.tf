# =============================================================================
# 1. CONFIGURACIÓN DE TERRAFORM Y BACKEND
# =============================================================================
terraform {
  # El backend "azurerm" le dice a Terraform que guarde el archivo .tfstate 
  # (la memoria de lo que ha creado) en una Storage Account de Azure.
  # Esto permite que GitHub Actions no intente duplicar recursos.
  backend "azurerm" {
    resource_group_name  = "rg-apppersonal-tfstate"
    storage_account_name = "stcarlosv3state"
    container_name       = "tfstate-apppersonal"
    key                  = "terraform.tfstate"
  }

  # Definimos qué proveedores externos necesitamos y sus versiones.
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm" # Para crear recursos en Azure (RG, AKS, SQL)
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"    # Para instalar aplicaciones en Kubernetes (Ingress)
      version = "~> 2.0"
    }
  }
}

# Configuramos el proveedor de Azure con sus características por defecto.
provider "azurerm" {
  features {}
}

# =============================================================================
# 2. INFRAESTRUCTURA DE RED Y CONTENEDORES
# =============================================================================

# Grupo de Recursos: El contenedor lógico donde vivirán todos los recursos v3.
resource "azurerm_resource_group" "rg" {
  name     = "RG-Laboratorio20-v3"
  location = "centralus"
}

# Azure Container Registry (ACR): El almacén privado para tus imágenes Docker.
resource "azurerm_container_registry" "acr" {
  name                = "acrcarlos69v3"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true # Permite usar credenciales de admin para el despliegue
}

# Azure Kubernetes Service (AKS): El orquestador donde correrá tu App Node.js.
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-lab-v3"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "akscarlosv3"

  default_node_pool {
    name       = "default"
    node_count = 1                  # Solo 1 nodo para ahorrar costos de laboratorio
    vm_size    = "Standard_B2ps_v2" # IMPORTANTE: Serie "p" para arquitectura ARM64
  }

  # Identidad asignada por el sistema para que el clúster gestione sus propios recursos.
  identity {
    type = "SystemAssigned"
  }
}

# =============================================================================
# 3. BASE DE DATOS SQL (PERSISTENCIA DE DATOS)
# =============================================================================

# Servidor de Base de Datos SQL: El motor que hospeda la base de datos.
resource "azurerm_mssql_server" "sqlserver" {
  name                         = "sqlserver-carlos-v3"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "Password1234!" 
}

# Base de Datos SQL Individual: Donde se guardarán los tickets de soporte.
resource "azurerm_mssql_database" "db" {
  name      = "ticketsdb-v3"
  server_id = azurerm_mssql_server.sqlserver.id
  sku_name  = "S0" # Nivel básico para pruebas
}

# Regla de Firewall: Permite que otros servicios de Azure (como AKS) lleguen al SQL.
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0" # IP especial que significa "Cualquier servicio de Azure"
  end_ip_address   = "0.0.0.0"
}

# =============================================================================
# 4. CONFIGURACIÓN DE HELM E INGRESS (GESTIÓN DE TRÁFICO)
# =============================================================================

# El proveedor de Helm necesita las credenciales del AKS que acabamos de crear.
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  }
}

# NGINX Ingress Controller: Instala el balanceador que recibirá el tráfico de internet
# y lo enviará a tu aplicación dentro de Kubernetes.
resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-basic"
  create_namespace = true # Crea el namespace "ingress-basic" automáticamente
  
  # CRÍTICO: Helm no puede instalarse si el clúster AKS no ha terminado de crearse.
  depends_on = [azurerm_kubernetes_cluster.aks]
}