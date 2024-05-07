# backend.tf

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-lamin-test"
    storage_account_name = "storagelamintest"
    container_name       = "terraformstate"
    key                  = "terraform.tfstate"
  }
}