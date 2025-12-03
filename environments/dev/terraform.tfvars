# Development Environment Configuration
environment = "dev"
location    = "East US"

# Resource naming
resource_group_name = "rg-ecommerce-microservices"
cluster_name        = "aks-ecommerce"
dns_prefix          = "ecommerce-k8s"

# Kubernetes version
kubernetes_version = "1.32"

# Networking
vnet_name          = "aks-vnet"
vnet_address_space = ["10.0.0.0/16"]
subnet_names       = ["aks-subnet", "appgw-subnet"]
subnet_prefixes    = ["10.0.1.0/24", "10.0.2.0/24"]

# Node pools - Development (smaller resources)
default_node_pool = {
  name            = "system"
  node_count      = 2
  vm_size         = "Standard_B2ms"
  os_disk_size_gb = 30
  type            = "VirtualMachineScaleSets"
  max_pods        = 30
}

# Additional node pools for specific workloads (optional for dev)
additional_node_pools = {}

# Security
rbac_enabled = true

# Azure Container Registry
acr_name          = "acrvingesoft"
acr_sku           = "Basic"
acr_admin_enabled = false

# Tags
tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Project     = "Ecommerce-Microservices"
  Owner       = "DevOps-Team"
  CostCenter  = "Engineering"
  Branch      = "develop"
}
