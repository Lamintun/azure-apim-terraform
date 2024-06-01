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

# variable "project_code" {
#   type = string
# }

variable "network" {
  type = any
}

variable "vnets" {
  type = map(any)
}