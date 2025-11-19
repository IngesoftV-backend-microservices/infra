variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Resource group name (will have environment suffix)"
  type        = string
}

variable "cluster_name" {
  description = "Kubernetes cluster name (will have environment suffix)"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for Kubernetes cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
  default     = "aks-vnet"
}

variable "vnet_address_space" {
  description = "Address space for VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_names" {
  description = "Names of subnets"
  type        = list(string)
  default     = ["aks-subnet", "appgw-subnet"]
}

variable "subnet_prefixes" {
  description = "Address prefixes for subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "default_node_pool" {
  description = "Default node pool configuration"
  type = object({
    name            = string
    node_count      = number
    vm_size         = string
    os_disk_size_gb = number
    type            = string
    max_pods        = number
  })
  default = {
    name            = "system"
    node_count      = 2
    vm_size         = "Standard_B2s"
    os_disk_size_gb = 30
    type            = "VirtualMachineScaleSets"
    max_pods        = 30
  }
}

variable "additional_node_pools" {
  description = "Additional node pools configuration"
  type = map(object({
    node_count      = number
    vm_size         = string
    os_disk_size_gb = number
    max_pods        = number
  }))
  default = {}
}

variable "rbac_enabled" {
  description = "Enable Kubernetes RBAC"
  type        = bool
  default     = true
}


variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "Ecommerce"
  }
}

