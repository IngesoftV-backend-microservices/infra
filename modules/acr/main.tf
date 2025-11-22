resource "azurerm_container_registry" "main" {
  name                = "${var.name}${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  tags = merge(var.tags, {
    Name = "${var.name}${var.environment}"
  })

  lifecycle {
    prevent_destroy = false
  }
}
