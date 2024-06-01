
locals {
  project_code   = module.utility.project_code
  env_code       = lookup(module.utility.environment_codes, var.environment)
  vnet_suffix    = lookup(module.utility.resource_suffixes, "azurerm_virtual_network")
  subnet_suffix  = lookup(module.utility.resource_suffixes, "azurerm_subnet")
  apim_vnet_code = module.utility.apim_vnet_user_defined_code

  vnet_info = {
    for v in var.network : join("-", [local.project_code, local.apim_vnet_code, "${lookup(module.utility.region_codes, v.location)}", "${local.env_code}-01", local.vnet_suffix]) => {
      address_space = v.vnet_address_space
      is_primary    = v.is_primary
      location      = v.location
    }
  }

  flattened_network_info = {
    for item in flatten([
      for v in var.network : [
        for s in v.subnets : {
          vnet_name                = join("-", [local.project_code, local.apim_vnet_code, "${lookup(module.utility.region_codes, v.location)}", "${local.env_code}-01", local.vnet_suffix])
          vnet_address_space       = v.vnet_address_space
          location                 = v.location
          is_primary               = v.is_primary
          subnet_user_defined_code = s.user_defined_code
          subnet_name              = join("-", [module.utility.project_code, s.user_defined_code, "${lookup(module.utility.region_codes, v.location)}", "${local.env_code}-01", local.subnet_suffix])
          subnet_address_space     = s.address_space
        }
      ]
    ]) :
    item.subnet_name => item
  }
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

module "utility" {
  source = "./modules/utility"
}

module "network" {
  source                  = "./modules/network"
  environment             = local.env_code
  resource_group_name     = data.azurerm_resource_group.rg.name
  resource_group_location = data.azurerm_resource_group.rg.location
  network                 = local.flattened_network_info
  vnets                   = local.vnet_info
}

module "apim" {
  source                     = "./modules/apim"
  environment                = local.env_code
  resource_group_name        = data.azurerm_resource_group.rg.name
  resource_group_location    = data.azurerm_resource_group.rg.location
  primary_location_subnet_id = module.network.primary_region_apim_subnet_id
  additional_location_list   = module.network.additional_region_apim_subnets
  sku                        = var.apim_sku
  publisher_email            = var.publisher_email
  publisher_name             = var.publisher_name
  capacity                   = 2
  vnets                      = module.network.vnets
  custom_domain_name         = var.apim_custom_domain_name
  portal_sub_domain          = var.apim_portal_sub_domain
  gateway_sub_domain         = var.apim_gateway_sub_domain
  management_sub_domain      = var.apim_management_sub_domain
}

module "gateway" {
  source                  = "./modules/appgateway"
  environment             = local.env_code
  project_code            = local.project_code
  resource_group_name     = data.azurerm_resource_group.rg.name
  resource_group_location = data.azurerm_resource_group.rg.location
  gateway_subnets         = module.network.gateway_subnets
  vnets                   = module.network.vnets
  gateway_capacity        = 2
  apim-private-ips        = module.apim.apim-private-ips
  apim_name               = module.apim.apim-name
  apim_endpoints = module.apim.apim_endpoints
  # custom_domain_name      = var.apim_custom_domain_name
  # portal_sub_domain       = var.apim_portal_sub_domain
  # gateway_sub_domain      = var.apim_gateway_sub_domain
  # management_sub_domain   = var.apim_management_sub_domain
}

