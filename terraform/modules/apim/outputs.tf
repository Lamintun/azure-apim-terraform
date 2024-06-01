output "apim-name"{
    value = azurerm_api_management.apim.name
}

output "apim-id" {
  value = azurerm_api_management.apim.id
}

output "apim-private-ips" {
  value = azurerm_api_management.apim.private_ip_addresses
}

output "apim_endpoints" {
  value = tolist([
    {
        "name" = "gateway",
        "endpoint" = "${azurerm_api_management.apim.name}.azure-api.net"
        
    },
    {      
        "name" = "portal"
        "endpoint" = "${azurerm_api_management.apim.name}.developer.azure-api.net",
    },
    {
        "name" = "management",
        "endpoint" = "${azurerm_api_management.apim.name}.azure-api.net"
    }          
  ])
}