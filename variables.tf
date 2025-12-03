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
  default     = "Canada Central"
}

variable "resource_group_name" {
  description = "Resource group name (will have environment suffix)"
  type        = string
  validation {
    condition     = length(var.resource_group_name) > 0 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

variable "cluster_name" {
  description = "Kubernetes cluster name (will have environment suffix)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$", var.cluster_name))
    error_message = "Cluster name must be lowercase alphanumeric with hyphens, 1-63 characters."
  }
}

variable "dns_prefix" {
  description = "DNS prefix for Kubernetes cluster"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,52}[a-z0-9]$", var.dns_prefix))
    error_message = "DNS prefix must be lowercase alphanumeric with hyphens, 1-54 characters."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.32"
  validation {
    condition     = can(regex("^1\\.(2[6-9]|[3-9][0-9])$", var.kubernetes_version))
    error_message = "Kubernetes version must be 1.26 or higher (format: 1.XX)."
  }
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
    priority        = optional(string, "Regular") # Regular or Spot
    eviction_policy = optional(string, "Delete")  # Delete or Deallocate (only for Spot)
    spot_max_price  = optional(number, null)      # Max price for Spot instances (-1 for on-demand price)
  }))
  default = {}
}

variable "rbac_enabled" {
  description = "Enable Kubernetes RBAC"
  type        = bool
  default     = true
}

variable "acr_name" {
  description = "Base name for ACR (alphanumeric only, will have environment suffix)"
  type        = string
  default     = "acrvingesofttaller2"
  validation {
    condition     = can(regex("^[a-zA-Z0-9]+$", var.acr_name))
    error_message = "ACR name must contain only alphanumeric characters."
  }
}

variable "acr_sku" {
  description = "SKU tier for ACR (Basic, Standard, Premium)"
  type        = string
  default     = "Basic"
}

variable "acr_admin_enabled" {
  description = "Enable admin user for ACR"
  type        = bool
  default     = false
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

variable "service_cidr" {
  description = "CIDR for Kubernetes services (must not overlap with VNet)"
  type        = string
  default     = "10.1.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address for DNS service (must be within service_cidr)"
  type        = string
  default     = "10.1.0.10"
}
