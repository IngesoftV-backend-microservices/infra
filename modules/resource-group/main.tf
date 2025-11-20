resource "azurerm_resource_group" "main" {
  name     = "${var.name}-${var.environment}"
  location = var.location
  tags     = merge(var.tags, {
    Name = "${var.name}-${var.environment}"
  })

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

