# backend.tf

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-nt-apim-poc"
    storage_account_name = "nttfbackendstate"
    container_name       = "nttfbackendstate"
    key                  = "update/terraform.tfstate"
  }
}