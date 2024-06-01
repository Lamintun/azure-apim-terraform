locals {

    region_short_codes = module.utility.region_codes
    ud_gateway_codes = tolist(module.utility.app_gateway_subnet_patterns)
    public_ip_suffix = lookup(module.utility.resource_suffixes, "azurerm_public_ip")
    app_gateway_suffix = lookup(module.utility.resource_suffixes, "azurerm_application_gateway")
    app_gateway_waf_suffix = lookup(module.utility.resource_suffixes, "azurerm_web_application_firewall_policy")
    user_assigned_id_suffix =  lookup(module.utility.resource_suffixes, "azurerm_user_assigned_identity")
    portal_url = "nt-poc-eus-multi-region-apim-developer.azure-api.net"
    gateway_url = "nt-poc-eus-multi-region-apim.azure-api.net"
    management_url = "nt-poc-eus-multi-region-apim-management.azure-api.net"

    endpoints = var.apim_endpoints
}

module "utility" {
  source = "../utility"  
}

resource "azurerm_public_ip" "publicip" {
  for_each = var.gateway_subnets
  name = join("-", ["${var.project_code}",
                  "${[for pattern in local.ud_gateway_codes : pattern if strcontains("${each.value.subnet.name}", pattern)][0]}",
                  "${lookup(local.region_short_codes, each.value.vnet.location)}",
                  "${var.environment}-01",
                  "${local.public_ip_suffix}"])
  
  
  resource_group_name = var.resource_group_name
  location = each.value.vnet.location
  domain_name_label = "${var.project_code}-${[for pattern in local.ud_gateway_codes : pattern if strcontains("${each.value.subnet.name}", pattern)][0]}-${lookup(local.region_short_codes, each.value.vnet.location)}"
  allocation_method = "Static"
  ip_version = "IPv4"
  sku = "Standard"
  sku_tier = "Regional"
}

resource "azurerm_user_assigned_identity" "uai" {
  depends_on = [ azurerm_public_ip.publicip ]
  for_each = var.vnets
  name                = "${var.project_code}-${local.app_gateway_suffix}-${lookup(local.region_short_codes, each.value.location)}-${var.environment}-01-${local.user_assigned_id_suffix}"
  resource_group_name = var.resource_group_name
  location            = each.value.location
}

resource "azurerm_web_application_firewall_policy" "waf" {
  depends_on = [ azurerm_user_assigned_identity.uai ]
  for_each = var.gateway_subnets
  name = join("-",["${var.project_code}",
                "${[for pattern in local.ud_gateway_codes : pattern if strcontains("${each.value.subnet.name}", pattern)][0]}",
                "${lookup(local.region_short_codes, each.value.vnet.location)}",
                "${var.environment}-01",
                "${local.app_gateway_waf_suffix}"])

  location = each.value.vnet.location
  resource_group_name = var.resource_group_name
  managed_rules {
    managed_rule_set {
      type = "Microsoft_BotManagerRuleSet"
      version = "0.1"
    }
    managed_rule_set {
      type = "OWASP"
      version = "3.2"      
    }
  }
  policy_settings {
    enabled                          = false
    file_upload_limit_in_mb          = 100
    max_request_body_size_in_kb      = 128
    mode                             = "Detection"
    request_body_check               = true
    request_body_inspect_limit_in_kb = 128
    }
}

resource "azurerm_application_gateway" "gateway" {
  depends_on = [ azurerm_web_application_firewall_policy.waf ]
  for_each = var.gateway_subnets
  name = join("-", 
                  [var.project_code,
                  [for pattern in local.ud_gateway_codes : pattern if strcontains("${each.value.subnet.name}", pattern)][0],
                  "${lookup(local.region_short_codes, each.value.vnet.location)}",
                  "${var.environment}-01",
                  local.app_gateway_suffix]
              )

  resource_group_name = var.resource_group_name
  location            = each.value.vnet.location

  firewall_policy_id = azurerm_web_application_firewall_policy.waf[each.value.subnet.name].id
  
  identity {
    type = "UserAssigned"
    identity_ids = [ azurerm_user_assigned_identity.uai[each.value.vnet.name].id ]
  }

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = var.gateway_capacity
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"    
    subnet_id = each.value.subnet.id
  }

  frontend_port {
    name = "frontend-port-http"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-public-ip-config"
    public_ip_address_id = azurerm_public_ip.publicip[each.value.subnet.name].id
  }

  frontend_ip_configuration {
    private_ip_address_allocation = "Static"
    name                 = "frontend-private-ip-config"
    private_ip_address = cidrhost(each.value.subnet.address_prefixes[0], 16)
    subnet_id = each.value.subnet.id
  }

  //Gateway backend pool
  dynamic "backend_address_pool" {
    for_each   = local.endpoints
    content {
      name = "${backend_address_pool.value.name}-backend-pool"
      fqdns = [backend_address_pool.value.endpoint]
    }
  }

  dynamic backend_http_settings {
    for_each   = local.endpoints 
    content {
      name                  = "${backend_http_settings.value.name}-http-backendsetting"
      cookie_based_affinity = "Disabled"
      port                  = 80
      
      pick_host_name_from_backend_address = true
      protocol              = "Http"
      request_timeout       = 30
      probe_name = "${backend_http_settings.value.name}-http-probe"
    }
  }


  dynamic probe {
    for_each   = local.endpoints 
    content {      
      name = "${probe.key}-http-probe"
      protocol = "Http"
      pick_host_name_from_backend_http_settings = true
      port = 80
      path = probe.key == "gateway" ? "/status-0123456789abcdef" : (probe.value.name == "portal" ? "/signin": "/ServiceStatus")
      interval = 30
      timeout = 300
      unhealthy_threshold = 3
    }
  }


  dynamic http_listener {
    for_each   = local.endpoints 
    content {
      name                           = "${http_listener.value.name}-http-listener"
      frontend_ip_configuration_name = "frontend-private-ip-config"
      frontend_port_name             = "frontend-port-http"
      protocol                       = "Http"
      host_name =  local.gateway_url
    }
  }

    dynamic request_routing_rule {
    for_each   = local.endpoints
      content {
        name                       = "${request_routing_rule.value.name}-http-routing-rule"
        priority                   = tonumber(request_routing_rule.key) + 1
        rule_type                  = "Basic"
        http_listener_name         = "${request_routing_rule.value.name}-http-listener"
        backend_address_pool_name  = "${request_routing_rule.value.name}-backend-pool"
        backend_http_settings_name = "${request_routing_rule.value.name}-http-backendsetting"
    }
  }

  # request_routing_rule {
  #   name                       = "gateway-http-routing-rule"
  #   priority                   = 1
  #   rule_type                  = "Basic"
  #   http_listener_name         = "gateway-http-listener"
  #   backend_address_pool_name  = "gateway-backend-pool"
  #   backend_http_settings_name = "gateway-http-backendsetting"
  # }

  # //Portal backend pool
  # backend_address_pool {    
  #   name = "portal-backend-pool"
  #   # ip_addresses = var.apim-private-ips
  #   fqdns = [local.portal_url]
  # }

  # backend_http_settings {
  #   name                  = "portal-http-backendsetting"
  #   cookie_based_affinity = "Disabled"
  #   port                  = 80
    
  #   pick_host_name_from_backend_address = true
  #   # host_name = "${var.portal_sub_domain}.${var.custom_domain_name}"
  #   protocol              = "Http"
  #   request_timeout       = 30
  #   probe_name = "portal-http-probe"
  # }

  # probe {
  #   name = "portal-http-probe"
  #   protocol = "Http"
  #   pick_host_name_from_backend_http_settings = true
  #   port = 80
  #   path = "/signin"
  #   interval = 30
  #   timeout = 300
  #   unhealthy_threshold = 3
  # }

  # http_listener {
  #   name                           = "portal-http-listener"
  #   frontend_ip_configuration_name = "frontend-private-ip-config"
  #   frontend_port_name             = "frontend-port-http"
  #   protocol                       = "Http"
  #   host_name =  local.portal_url
  # }

  # request_routing_rule {
  #   name                       = "portal-http-routing-rule"
  #   priority                   = 2
  #   rule_type                  = "Basic"
  #   http_listener_name         = "portal-http-listener"
  #   backend_address_pool_name  = "portal-backend-pool"
  #   backend_http_settings_name = "portal-http-backendsetting"
  # }

  # //Management backend pool
  # backend_address_pool {    
  #   name = "management-backend-pool"
  #   # ip_addresses = var.apim-private-ips
  #   fqdns = [local.management_url]
  # }

  # backend_http_settings {
  #   name                  = "management-http-backendsetting"
  #   cookie_based_affinity = "Disabled"
  #   port                  = 80
    
  #   pick_host_name_from_backend_address = true
  #   # host_name = "${var.management_sub_domain}.${var.custom_domain_name}"
  #   protocol              = "Http"
  #   request_timeout       = 30
  #   probe_name = "management-http-probe"
  # }

  # probe {
  #   name = "management-http-probe"
  #   protocol = "Http"
  #   pick_host_name_from_backend_http_settings = true
  #   port = 80
  #   path = "/ServiceStatus"
  #   interval = 30
  #   timeout = 300
  #   unhealthy_threshold = 3
  # }

  # http_listener {
  #   name                           = "management-http-listener"
  #   frontend_ip_configuration_name = "frontend-private-ip-config"
  #   frontend_port_name             = "frontend-port-http"
  #   protocol                       = "Http"
  #   host_name =  local.management_url
  # }

  # request_routing_rule {
  #   name                       = "management-http-routing-rule"
  #   priority                   = 3
  #   rule_type                  = "Basic"
  #   http_listener_name         = "management-http-listener"
  #   backend_address_pool_name  = "management-backend-pool"
  #   backend_http_settings_name = "management-http-backendsetting"
  # }
}
