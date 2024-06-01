variable "resource_group_location" {
  type        = string
  description = "Location of the resource group."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name."
}

variable "environment" {
  type = string
  description = "Environment name"
}

variable "project_code" {
  type = string
}

variable "vnets"{
  type = any
}

variable "gateway_subnets" {
  type = any  
}

variable "gateway_capacity" {
  type = number  
}

variable "apim-private-ips" {
  type = list(string)
}

variable "apim_name"{
  type = string
  description = "APIM name"
}

variable "apim_endpoints" {
  type = list(any)
}
