locals {  
  region_short_codes = module.utility.region_codes
  project_code = module.utility.project_code
  subnet_suffix = lookup(module.utility.resource_suffixes, "azurerm_subnet")
  vnet_suffix = lookup(module.utility.resource_suffixes, "azurerm_virtual_network")
  nsg_suffix = lookup(module.utility.resource_suffixes, "azurerm_network_security_group")
  vnet_code = lookup(module.utility.resource_suffixes, "azurerm_virtual_network")
}

module "utility" {
  source = "../utility"
}

resource "azurerm_virtual_network" "vnet" {
  for_each = var.vnets
  name                = each.key
  location            = each.value.location
  resource_group_name = var.resource_group_name
  address_space       = [each.value.address_space] 
}

resource "azurerm_subnet" "subnet" {
  depends_on = [ azurerm_virtual_network.vnet ]
  for_each = var.network
  name = each.value.subnet_name
  address_prefixes = [each.value.subnet_address_space]
  resource_group_name = var.resource_group_name
  virtual_network_name = each.value.vnet_name
}

resource "azurerm_network_security_group" "nsg" {
  depends_on = [ azurerm_subnet.subnet ]
  for_each = azurerm_subnet.subnet
  name = replace(each.value.name,local.subnet_suffix,local.nsg_suffix)
  resource_group_name = each.value.resource_group_name
  location = azurerm_virtual_network.vnet[each.value.virtual_network_name].location 
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  depends_on = [ azurerm_network_security_group.nsg ]
  for_each = azurerm_subnet.subnet
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.nsg[each.value.name].id
}