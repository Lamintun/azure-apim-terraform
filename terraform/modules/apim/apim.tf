locals {
    project_code   = module.utility.project_code
    region_short_codes = module.utility.region_codes
    apim_suffix = lookup(module.utility.resource_suffixes, "azurerm_api_management")
    vnet_link_suffix =  lookup(module.utility.resource_suffixes, "azurerm_private_dns_zone_virtual_network_link")
}

module "utility" {
  source = "../utility"
}

resource "azurerm_api_management" "apim" {
  name                = join("-", [local.project_code, "${lookup(module.utility.region_codes, var.resource_group_location)}-01", local.apim_suffix])
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  publisher_email     = var.publisher_email
  publisher_name      = var.publisher_name
  sku_name            = "${var.sku}_${var.sku_count}"
  virtual_network_type                = "Internal"  

  sign_in {
    enabled = true
  }


  virtual_network_configuration {
    subnet_id = var.primary_location_subnet_id    
  } 

  dynamic "additional_location" {
    for_each = var.additional_location_list
    content {
      location = additional_location.value.vnet.location 
      virtual_network_configuration {    
        subnet_id = additional_location.value.subnet.id
      }
    }
  }
}

# resource "azurerm_private_dns_zone" "dnszone" {
#   name                = var.custom_domain_name
#   resource_group_name = var.resource_group_name
# }

# resource "azurerm_private_dns_a_record" "portal" {
#   name                = var.portal_sub_domain
#   zone_name           = azurerm_private_dns_zone.dnszone.name
#   resource_group_name = var.resource_group_name
#   ttl                 = 300
#   records             = azurerm_api_management.apim.private_ip_addresses
# }

# resource "azurerm_private_dns_a_record" "management" {
#   name                = var.management_sub_domain
#   zone_name           = azurerm_private_dns_zone.dnszone.name
#   resource_group_name = var.resource_group_name
#   ttl                 = 300
#   records             = azurerm_api_management.apim.private_ip_addresses
# }

# resource "azurerm_private_dns_a_record" "gateway" {
#   name                = var.gateway_sub_domain
#   zone_name           = azurerm_private_dns_zone.dnszone.name
#   resource_group_name = var.resource_group_name
#   ttl                 = 300
#   records             = azurerm_api_management.apim.private_ip_addresses
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "example" {
#   for_each = var.vnets
#   name                  = join("-", [local.project_code, "${lookup(module.utility.region_codes, var.resource_group_location)}-01", local.vnet_link_suffix])
#   resource_group_name   = var.resource_group_name
#   private_dns_zone_name = azurerm_private_dns_zone.dnszone.name
#   virtual_network_id    = each.value.id
# }