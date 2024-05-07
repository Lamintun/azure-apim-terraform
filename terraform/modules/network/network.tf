resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/20"]
}

resource "azurerm_subnet" "subnet" {
  name                                           = var.subnet_name
  resource_group_name                            = azurerm_virtual_network.vnet.resource_group_name
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  address_prefixes                               = [cidrsubnet("10.0.0.0/20", 2, 1)]
#   service_endpoints                              = ["Microsoft.KeyVault"]  
}