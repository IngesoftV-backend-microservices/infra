variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
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
}

variable "additional_node_pools" {
  description = "Additional node pools configuration"
  type = map(object({
    node_count      = number
    vm_size         = string
    os_disk_size_gb = number
    max_pods        = number
    priority        = optional(string, "Regular")  # Regular or Spot
    eviction_policy = optional(string, "Delete")    # Delete or Deallocate (only for Spot)
    spot_max_price  = optional(number, null)        # Max price for Spot instances (-1 for on-demand price)
  }))
  default = {}
}

variable "vnet_subnet_id" {
  description = "Subnet ID for the default node pool"
  type        = string
}

variable "rbac_enabled" {
  description = "Enable RBAC"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "10.1.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address for DNS service (must be within service_cidr)"
  type        = string
  default     = "10.1.0.10"
}
