provider "azurerm" {
  subscription_id = ""
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

# Data sources
data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

# Resource Group
module "resource_group" {
  source = "./modules/resource-group"
  
  name        = var.resource_group_name
  environment = var.environment
  location    = var.location
  tags        = var.tags
}

# Networking
module "networking" {
  source = "./modules/networking"
  
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  environment         = var.environment
  vnet_name           = var.vnet_name
  address_space       = var.vnet_address_space
  subnet_names        = var.subnet_names
  subnet_prefixes     = var.subnet_prefixes
  tags                = var.tags
}

# Kubernetes Cluster
module "kubernetes_cluster" {
  source = "./modules/kubernetes-cluster"
  
  cluster_name            = var.cluster_name
  environment             = var.environment
  resource_group_name     = module.resource_group.name
  location                = module.resource_group.location
  dns_prefix              = var.dns_prefix
  kubernetes_version      = var.kubernetes_version
  
  # Network configuration
  vnet_subnet_id          = module.networking.aks_subnet_id
  
  # Node pools
  default_node_pool       = var.default_node_pool
  additional_node_pools  = var.additional_node_pools
  
  # Security
  rbac_enabled = var.rbac_enabled
  
  tags = var.tags
}

# Outputs are defined in outputs.tf

