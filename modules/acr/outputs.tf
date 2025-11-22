output "id" {
  description = "The ID of the ACR"
  value       = azurerm_container_registry.main.id
}

output "name" {
  description = "The name of the ACR"
  value       = azurerm_container_registry.main.name
}

output "login_server" {
  description = "The login server URL of the ACR"
  value       = azurerm_container_registry.main.login_server
}

output "admin_username" {
  description = "The admin username of the ACR"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "admin_password" {
  description = "The admin password of the ACR"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}
