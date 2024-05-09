variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location for all resources."
}

variable "resource_group_name" {
  type        = string
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "vnet_name" {
  type        = string
  default     = "vnet-lamin-test"
  description = "Virtual network name"
}

variable "subnet_name" {
  type        = string
  default     = "subnet-lamin-test"
  description = "Subnet name"
}

variable "nsg_name" {
  type        = string
  default     = "nsg-lamin-test"
  description = "Subnet name"
}
