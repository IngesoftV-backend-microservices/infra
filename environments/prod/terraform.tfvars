# Production Environment Configuration
environment = "prod"
location    = "East US 2" # Changed to avoid quota limit in East US

# Resource naming
resource_group_name = "rg-ecommerce-microservices"
cluster_name        = "aks-ecommerce"
dns_prefix          = "ecommerce-k8s"

# Kubernetes version
kubernetes_version = "1.32"

# Networking
vnet_name          = "aks-vnet"
vnet_address_space = ["10.1.0.0/16"]
subnet_names       = ["aks-subnet", "appgw-subnet"]
subnet_prefixes    = ["10.1.1.0/24", "10.1.2.0/24"]

# Service CIDR (Must NOT overlap with VNet address space)
service_cidr   = "10.2.0.0/16"
dns_service_ip = "10.2.0.10"

# Node pools - Production (Same topology as dev but larger VM)
default_node_pool = {
  name            = "system"
  node_count      = 2
  vm_size         = "Standard_B2ms"
  os_disk_size_gb = 50
  type            = "VirtualMachineScaleSets"
  max_pods        = 50
}

# No additional node pools, same as dev
additional_node_pools = {}

# Security
rbac_enabled = true

# Tags
tags = {
  Environment = "prod"
  ManagedBy   = "Terraform"
  Project     = "Ecommerce-Microservices"
  Owner       = "DevOps-Team"
  CostCenter  = "Production"
  Branch      = "main"
  Criticality = "High"
}
