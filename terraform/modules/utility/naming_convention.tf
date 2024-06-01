# NT resource naming convention : {project_code}-{user_defined_code}-{region_code}-{environment_code}-{index}-{resource_suffix}

locals {
  project_code = "nt-poc"

  user_defined_codes = {
    "inbound_public_gateway_subnet_user_defined_code" : "inbound-public"
    "inbound_private_gateway_subnet_user_defined_code" : "inbound-private"
    "inbound_internal_gateway_subnet_user_defined_code" : "inbound-internal"
    "outbound_gateway_subnet_user_defined_code" : "outbound"
    "apim_vnet_user_defined_code" : "apim"
    "apim_subnet_user_defined_code" : "apim"
    "apim_user_defined_code" : ""
  }

  environment_codes = {
    "dev" : "d"
    "qa" : "q"
    "uat" : "u"
    "stage" : "s"
    "prod" : "p"
  }

  region_codes = {
    "eastus"  : "eus"
    "westus"  : "wus"
    "centralus" : "cus"
  }

  resource_suffixes = {
    "azurerm_virtual_network"  : "vnet"
    "azurerm_subnet" : "snet"
    "azurerm_application_gateway" : "gwy"
    "azurerm_cdn_frontdoor_origin" : "fdr"
    "azurerm_public_ip" : "pip"
    "azurerm_network_security_group" : "nsg"
    "vm" : "vm"
    "dns_zone" : "dnsz"
    "azurerm_user_assigned_identity" : "uai"
    "azurerm_web_application_firewall_policy" : "waf"
    "azurerm_api_management" : "apim"
    "azurerm_private_dns_zone_virtual_network_link" : "vlink"
  }
}

