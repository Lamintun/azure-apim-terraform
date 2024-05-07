
resource "azurerm_resource_group" "resourcegroup" {
  name     = "rg-lamin-terraform-apim-test"
  location = "eastus"
}

module "network" {
  source                  = "./modules/network"
  resource_group_name     = azurerm_resource_group.resourcegroup.name
  resource_group_location = azurerm_resource_group.resourcegroup.location
}

module "apim" {
  source                  = "./modules/apim"
  resource_group_name     = azurerm_resource_group.resourcegroup.name
  resource_group_location = azurerm_resource_group.resourcegroup.location
  subnet_id = module.network.subnet_id
}