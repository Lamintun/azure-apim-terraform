locals {
  # User-defined codes for gateways NSG names
  app_gateway_subnet_patterns = module.utility.app_gateway_subnet_patterns

  # APIM subnet pattern based on the user-defined code
  apim_subnet_pattern = module.utility.apim_subnet_user_defined_code

  # Filter app gateway subnet NSGs based on the user-defined codes
  filtered_app_gateway_nsgs = {
    for name, nsg in azurerm_network_security_group.nsg :
      name => nsg if anytrue([for pattern in local.app_gateway_subnet_patterns : strcontains(name, pattern)])
  }

  # Filter APIM subnet NSGs
  filtered_apim_nsgs = {
    for name, nsg in azurerm_network_security_group.nsg :
      name => nsg if strcontains(name, local.apim_subnet_pattern)
  }

  # Flatten the planned virtual networks and subnets, and add subnet name as index for each item in the list
  flattened_subnets = {
    for s in azurerm_subnet.subnet : s.name => {      
        subnet = s
        vnet = azurerm_virtual_network.vnet[s.virtual_network_name]
      }    
  }

  primary_apim_subnet = tolist([
    for item in var.network :
      item if item.is_primary == true && strcontains(item.subnet_user_defined_code, local.apim_subnet_pattern)
  ])
}

#region Application gateway subnets NSG rule
resource "azurerm_network_security_rule" "gateway_subnet_to_apim_subnet" {
  count = length(values(local.filtered_app_gateway_nsgs))
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "gateway_subnet_apim_subnet${tostring(count.index)}"
  priority                    = 109 + (count.index)
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_ranges     = ["80","443"]
  source_address_prefixes   = local.flattened_subnets[replace(values(local.filtered_app_gateway_nsgs)[count.index].name,local.nsg_suffix,local.subnet_suffix)].subnet.address_prefixes
  destination_address_prefixes = azurerm_subnet.subnet[local.primary_apim_subnet[0].subnet_name].address_prefixes
  network_security_group_name =  replace(local.primary_apim_subnet[0].subnet_name,local.subnet_suffix,local.nsg_suffix)
  resource_group_name =    values(local.filtered_app_gateway_nsgs)[count.index].resource_group_name
}

resource "azurerm_network_security_rule" "gateway_manager_to_network" {
  for_each = local.filtered_app_gateway_nsgs
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "gatewaymanager_to_network"
  priority                    = 100
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "65200-65535"
  source_address_prefix   = "GatewayManager"
  destination_address_prefix = "*"
  network_security_group_name = each.value.name
  resource_group_name =    each.value.resource_group_name
}

resource "azurerm_network_security_rule" "gateway_internet_to_network" {
  for_each = local.filtered_app_gateway_nsgs
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "internet_to_network"
  priority                    = 101
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_ranges     = ["80","443"]
  source_address_prefix   = "Internet"
  destination_address_prefix = "*"
  network_security_group_name = each.value.name
  resource_group_name =    each.value.resource_group_name
}
resource "azurerm_network_security_rule" "gateway_loadbalancer_to_apim" {
  for_each = local.filtered_app_gateway_nsgs
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "loadbalancer_to_apim"
  network_security_group_name = each.value.name
  priority                    = 102
  protocol                    = "Tcp"
  resource_group_name         = each.value.resource_group_name

  source_port_range          = "*"
  destination_port_range     = "6390"  
  source_address_prefix      = "AzureLoadBalancer"
  destination_address_prefix = "VirtualNetwork"
}

resource "azurerm_network_security_rule" "gateway_trafficmanager_to_apim" {
  for_each = local.filtered_app_gateway_nsgs
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "trafficmanager_to_apim"
  network_security_group_name = each.value.name
  priority                    = 103
  protocol                    = "Tcp"
  resource_group_name         = each.value.resource_group_name

  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefix      = "AzureTrafficManager"
  destination_address_prefix = "VirtualNetwork"
}
#endregion

#region Primary APIM subnet NSG rules
resource "azurerm_network_security_rule" "client_to_apim" {
  for_each = local.filtered_apim_nsgs
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "client_to_apim"
  network_security_group_name = each.value.name
  priority                    = 100
  protocol                    = "Tcp"
  resource_group_name         = each.value.resource_group_name

  source_port_range          = "*"
  destination_port_ranges     = ["80","443"]
  source_address_prefix      = "Internet"
  destination_address_prefix = "VirtualNetwork"
}

resource "azurerm_network_security_rule" "management_via_portal_and_powershell" {
  for_each = local.filtered_apim_nsgs
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "management_for_portal_and_powershell"
  network_security_group_name = each.value.name
  priority                    = 101
  protocol                    = "Tcp"
  resource_group_name         = each.value.resource_group_name

  source_port_range          = "*"
  destination_port_range     = "3443"
  source_address_prefix      = "ApiManagement"
  destination_address_prefix = "VirtualNetwork"
}

resource "azurerm_network_security_rule" "loadbalancer_to_apim" {
  for_each = local.filtered_apim_nsgs
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "loadbalancer_to_apim"
  network_security_group_name = each.value.name
  priority                    = 102
  protocol                    = "Tcp"
  resource_group_name         = each.value.resource_group_name

  source_port_range          = "*"
  destination_port_range     = "6390"  
  source_address_prefix      = "AzureLoadBalancer"
  destination_address_prefix = "VirtualNetwork"
}

resource "azurerm_network_security_rule" "trafficmanager_to_apim" {
  for_each = local.filtered_apim_nsgs
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "trafficmanager_to_apim"
  network_security_group_name = each.value.name
  priority                    = 103
  protocol                    = "Tcp"
  resource_group_name         = each.value.resource_group_name

  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefix      = "AzureTrafficManager"
  destination_address_prefix = "VirtualNetwork"
}

resource "azurerm_network_security_rule" "apim_to_storage" {
  for_each = local.filtered_apim_nsgs
  access                      = "Allow"
  direction                   = "Outbound"
  name                        = "apim_to_storage"
  network_security_group_name = each.value.name
  priority                    = 104
  protocol                    = "Tcp"
  resource_group_name         = each.value.resource_group_name

  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefix      = "VirtualNetwork"
  destination_address_prefix = "Storage"
}

resource "azurerm_network_security_rule" "apim_to_sql" {
  for_each = local.filtered_apim_nsgs
  access                      = "Allow"
  direction                   = "Outbound"
  name                        = "apim_to_sql"
  network_security_group_name = each.value.name
  priority                    = 105
  protocol                    = "Tcp"
  resource_group_name         = each.value.resource_group_name

  source_port_range          = "*"
  destination_port_range     = "1443"
  source_address_prefix      = "VirtualNetwork"
  destination_address_prefix = "SQL"
}

resource "azurerm_network_security_rule" "apim_to_keyvault" {
  for_each = local.filtered_apim_nsgs
  access                      = "Allow"
  direction                   = "Outbound"
  name                        = "apim_to_keyvault"
  network_security_group_name = each.value.name
  priority                    = 106
  protocol                    = "Tcp"
  resource_group_name         = each.value.resource_group_name

  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefix      = "VirtualNetwork"
  destination_address_prefix = "AzureKeyVault"
}

resource "azurerm_network_security_rule" "apim_to_monitor" {
  for_each = local.filtered_apim_nsgs
  access                      = "Allow"
  direction                   = "Outbound"
  name                        = "apim_to_monitor"
  network_security_group_name = each.value.name
  priority                    = 107
  protocol                    = "Tcp"
  resource_group_name         = each.value.resource_group_name

  source_port_range          = "*"
  destination_port_ranges     = ["443","1886"]
  source_address_prefix      = "VirtualNetwork"
  destination_address_prefix = "AzureMonitor"
}

resource "azurerm_network_security_rule" "gateway_manager_to_apim" {
  for_each = local.filtered_apim_nsgs
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "gatewaymanager_to_apimk"
  priority                    = 108
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "65200-65535"
  source_address_prefix   = "GatewayManager"
  destination_address_prefix = "*"
  network_security_group_name = each.value.name
  resource_group_name =    each.value.resource_group_name
}
#endregion