resource "azurerm_resource_group" "main" {
  name     = "${var.name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

