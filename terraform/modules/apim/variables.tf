variable "environment"{
  type = string
}

variable "resource_group_location" {
  type        = string
  description = "Location for all resources."
}

variable "resource_group_name" {
  type        = string
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "custom_domain_name"{
  type = string
  description = "Custom domain name for APIM"
}

variable "portal_sub_domain" {
  type = string
  description = "Custom sub domain name for developer portal"
}

variable "gateway_sub_domain" {
  type = string
  description = "Custom sub domain name for API gateway"
}

variable "management_sub_domain" {
  type = string
  description = "Custom sub domain name for management portal"
}

variable "primary_location_subnet_id" {
  type        = string
  description = "Subnet id of the virtual network in primary region."
}

variable "additional_location_list" {
  type        = any
  description = "Subnet id of the virtual network in additional regions."
}

variable "publisher_email" {
  type        = string
  description = "The email address of the owner of the service"
  validation {
    condition     = length(var.publisher_email) > 0
    error_message = "The publisher_email must contain at least one character."
  }
}

variable "publisher_name" {
  type        = string
  description = "The name of the owner of the service"
  validation {
    condition     = length(var.publisher_name) > 0
    error_message = "The publisher_name must contain at least one character."
  }
}

variable "sku" {
  type        = string
  description = "The pricing tier of this API Management service"
  validation {
    condition     = contains(["Developer", "Standard", "Premium"], var.sku)
    error_message = "The sku must be one of the following: Developer, Standard, Premium."
  }
}

variable "sku_count" {
  default     = 1
  type        = number
  description = "The instance size of this API Management service."
  validation {
    condition     = contains([1, 2], var.sku_count)
    error_message = "The sku_count must be one of the following: 1, 2."
  }
}

variable "capacity" {
  type = number
}

variable "vnets"{
  type = any
}