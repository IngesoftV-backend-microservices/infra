output "name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "id" {
  description = "Resource group ID"
  value       = azurerm_resource_group.main.id
}

output "location" {
  description = "Resource group location"
  value       = azurerm_resource_group.main.location
}

