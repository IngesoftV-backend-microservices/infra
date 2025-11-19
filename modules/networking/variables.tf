variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "address_space" {
  description = "Address space for VNet"
  type        = list(string)
}

variable "subnet_names" {
  description = "Names of subnets"
  type        = list(string)
}

variable "subnet_prefixes" {
  description = "Address prefixes for subnets"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

