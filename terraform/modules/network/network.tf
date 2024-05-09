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

resource "azurerm_network_security_group" "nsg" {
  name = var.nsg_name
  resource_group_name = azurerm_virtual_network.vnet.resource_group_name
  location = azurerm_virtual_network.vnet.location
  
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_security_rule" "client_to_apim" {
  count                       = 1
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "client_to_apim"
  network_security_group_name = azurerm_network_security_group.nsg.name
  priority                    = 100
  protocol                    = "Tcp"
  resource_group_name         = azurerm_subnet.subnet.resource_group_name

  source_port_range          = "*"
  destination_port_ranges     = ["80","443"]
  source_address_prefix      = "Internet"
  destination_address_prefix = "VirtualNetwork"
}

resource "azurerm_network_security_rule" "management_for_portal_and_powershell" {
  count                       = 1
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "management_for_portal_and_powershell"
  network_security_group_name = azurerm_network_security_group.nsg.name
  priority                    = 101
  protocol                    = "Tcp"
  resource_group_name         = azurerm_virtual_network.vnet.resource_group_name

  source_port_range          = "*"
  destination_port_range     = "3443"
  source_address_prefix      = "ApiManagement"
  destination_address_prefix = "VirtualNetwork"
}

resource "azurerm_network_security_rule" "loadbalancer_to_apim" {
  count                       = 1
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "loadbalancer_to_apim"
  network_security_group_name = azurerm_network_security_group.nsg.name
  priority                    = 102
  protocol                    = "Tcp"
  resource_group_name         = azurerm_virtual_network.vnet.resource_group_name

  source_port_range          = "*"
  destination_port_range     = "6390"
  source_address_prefix      = "AzureLoadBalancer"
  destination_address_prefix = "VirtualNetwork"
}

resource "azurerm_network_security_rule" "trafficmanager_to_apim" {
  count                       = 1
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "trafficmanager_to_apim"
  network_security_group_name = azurerm_network_security_group.nsg.name
  priority                    = 103
  protocol                    = "Tcp"
  resource_group_name         = azurerm_virtual_network.vnet.resource_group_name

  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefix      = "AzureTrafficManager"
  destination_address_prefix = "VirtualNetwork"
}

resource "azurerm_network_security_rule" "apim_to_storage" {
  count                       = 1
  access                      = "Allow"
  direction                   = "Outbound"
  name                        = "apim_to_storage"
  network_security_group_name = azurerm_network_security_group.nsg.name
  priority                    = 100
  protocol                    = "Tcp"
  resource_group_name         = azurerm_virtual_network.vnet.resource_group_name

  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefix      = "VirtualNetwork"
  destination_address_prefix = "Storage"
}

resource "azurerm_network_security_rule" "apim_to_sql" {
  count                       = 1
  access                      = "Allow"
  direction                   = "Outbound"
  name                        = "apim_to_sql"
  network_security_group_name = azurerm_network_security_group.nsg.name
  priority                    = 101
  protocol                    = "Tcp"
  resource_group_name         = azurerm_virtual_network.vnet.resource_group_name

  source_port_range          = "*"
  destination_port_range     = "1443"
  source_address_prefix      = "VirtualNetwork"
  destination_address_prefix = "SQL"
}

resource "azurerm_network_security_rule" "apim_to_keyvault" {
  count                       = 1
  access                      = "Allow"
  direction                   = "Outbound"
  name                        = "apim_to_keyvault"
  network_security_group_name = azurerm_network_security_group.nsg.name
  priority                    = 102
  protocol                    = "Tcp"
  resource_group_name         = azurerm_virtual_network.vnet.resource_group_name

  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefix      = "VirtualNetwork"
  destination_address_prefix = "AzureKeyVault"
}

resource "azurerm_network_security_rule" "apim_to_monitor" {
  count                       = 1
  access                      = "Allow"
  direction                   = "Outbound"
  name                        = "apim_to_monitor"
  network_security_group_name = azurerm_network_security_group.nsg.name
  priority                    = 103
  protocol                    = "Tcp"
  resource_group_name         = azurerm_virtual_network.vnet.resource_group_name

  source_port_range          = "*"
  destination_port_ranges     = ["443","1886"]
  source_address_prefix      = "VirtualNetwork"
  destination_address_prefix = "AzureMonitor"
}