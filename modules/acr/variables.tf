variable "name" {
  description = "Base name for the ACR (must be globally unique, alphanumeric only)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9]+$", var.name))
    error_message = "ACR name must contain only alphanumeric characters."
  }
}

variable "environment" {
  description = "Environment suffix (dev, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for the ACR"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sku" {
  description = "SKU tier for ACR (Basic, Standard, Premium)"
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be Basic, Standard, or Premium."
  }
}

variable "admin_enabled" {
  description = "Enable admin user for ACR (not recommended for production)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the ACR"
  type        = map(string)
  default     = {}
}
