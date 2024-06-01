
output "primary_region_apim_subnet_id" {
  value = azurerm_subnet.subnet[local.primary_apim_subnet[0].subnet_name].id
}

output "primary_region_apim_vnet_id" {
  value = azurerm_virtual_network.vnet[local.primary_apim_subnet[0].vnet_name].id
}

output "additional_region_apim_subnets" {
  value = {
    for name,item in local.flattened_subnets :
    name => item if strcontains(item.subnet.name, local.apim_subnet_pattern) && item.subnet.name != local.primary_apim_subnet[0].subnet_name
  }
}

output "gateway_subnets" {
  value = {
      for name, item in local.flattened_subnets :
      name => item if anytrue([for pattern in local.app_gateway_subnet_patterns : strcontains(name, pattern)])
  }
}

output "vnets" {
  value = {
      for name, item in azurerm_virtual_network.vnet :
      name => item
  }
}

