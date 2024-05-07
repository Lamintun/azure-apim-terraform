
resource "azurerm_resource_group" "resourcegroup" {
  name     = "rg-lamin-terraform-apim-test"
  location = "eastus"
}

module "apim" {
  source                  = "./modules/apim"
  resource_group_name     = azurerm_resource_group.resourcegroup.name
  resource_group_location = azurerm_resource_group.resourcegroup.location
}