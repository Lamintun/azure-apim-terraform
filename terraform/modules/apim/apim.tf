resource "azurerm_api_management" "apim" {
  name                = var.apim_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  publisher_email     = var.publisher_email
  publisher_name      = var.publisher_name
  sku_name            = "${var.sku}_${var.sku_count}"

  virtual_network_type                = "External"  
  virtual_network_configuration {
    subnet_id = var.subnet_id
  }
  
}