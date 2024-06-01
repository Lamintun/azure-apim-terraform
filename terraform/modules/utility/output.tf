# NT resource naming convention : {project_code}-{user_defined_code}-{region_code}-{index}-{resource_suffix}

output "project_code" {
    value = local.project_code
}

output "user_defined_codes"{
  value = tomap(local.user_defined_codes)
}

output "environment_codes" {
  value = tomap(local.environment_codes)
}

output "region_codes" {
  value = tomap(local.region_codes)
}

output "resource_suffixes" {
  value = tomap(local.resource_suffixes)
}

output "inbound_public_gateway_subnet_user_defined_code" {
    value = local.user_defined_codes["inbound_public_gateway_subnet_user_defined_code"]
}

output "inbound_private_gateway_subnet_user_defined_code" {
    value = local.user_defined_codes["inbound_private_gateway_subnet_user_defined_code"]
}

output "inbound_internal_gateway_subnet_user_defined_code" {
    value = local.user_defined_codes["inbound_internal_gateway_subnet_user_defined_code"]
}

output "outbound_gateway_subnet_user_defined_code" {
    value = local.user_defined_codes["outbound_gateway_subnet_user_defined_code"]
}


output "apim_vnet_user_defined_code" {
  value = local.user_defined_codes["apim_vnet_user_defined_code"]
}

output "apim_subnet_user_defined_code" {
  value = local.user_defined_codes["apim_subnet_user_defined_code"]
}

output "app_gateway_subnet_patterns" {
    value = [
      local.user_defined_codes["inbound_public_gateway_subnet_user_defined_code"], 
      local.user_defined_codes["inbound_private_gateway_subnet_user_defined_code"], 
      local.user_defined_codes["inbound_internal_gateway_subnet_user_defined_code"],
      local.user_defined_codes["outbound_gateway_subnet_user_defined_code"]
    ]
}

