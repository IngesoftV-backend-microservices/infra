resource "azurerm_virtual_network" "main" {
  name                = "${var.vnet_name}-${var.environment}"
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet" "main" {
  count                = length(var.subnet_names)
  name                 = "${var.subnet_names[count.index]}-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_prefixes[count.index]]
}


