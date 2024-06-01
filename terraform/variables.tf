variable "environment" {
  type    = string
  default = "dev"
}
variable "resource_group_name" {
  type    = string
  default = "rg-nt-apim-poc"
}

variable "resource_group_location" {
  type    = string
  default = "eastus"
}

variable "apim_name" {
  type    = string
  default = "nt-poc-eus-multi-region-apim"
}

variable "apim_sku" {
  type    = string
  default = "Premium"
}

variable "publisher_email" {
  type    = string
  default = "lamin.tun@slalom.com"
}

variable "publisher_name" {
  type    = string
  default = "La Min Tun"
}

variable "apim_custom_domain_name" {
  type    = string
  default = "lamintun.com"
}

variable "apim_portal_sub_domain" {
  type    = string
  default = "portal"
}

variable "apim_gateway_sub_domain" {
  type    = string
  default = "gateway"
}

variable "apim_management_sub_domain" {
  type    = string
  default = "management"
}

variable "network" {
  type = any
  default = [
    {
      "location"           = "eastus"
      "is_primary"         = true
      "vnet_address_space" = "10.90.0.0/20",
      "subnets" = [
        {
          "user_defined_code" = "apim",
          "address_space"     = "10.90.0.0/28"
        },
        {
          "user_defined_code" = "inbound-public",
          "address_space"     = "10.90.1.0/24"
        },
        {
          "user_defined_code" = "inbound-private",
          "address_space"     = "10.90.2.0/24"
        },
        {
          "user_defined_code" = "inbound-internal",
          "address_space"     = "10.90.3.0/24"
        },
        {
          "user_defined_code" = "outbound",
          "address_space"     = "10.90.4.0/24"
        }
      ]
    },
    # {
    #   "location"           = "westus"
    #   "is_primary"         = false
    #   "vnet_address_space" = "10.91.0.0/20",
    #   "subnets" = [
    #     {
    #       "user_defined_code" = "apim",
    #       "address_space"     = "10.91.0.0/28"
    #     },
    #     {
    #       "user_defined_code" = "inbound-public",
    #       address_space       = "10.91.1.0/24"
    #     },
    #     {
    #       user_defined_code = "inbound-private",
    #       address_space     = "10.91.2.0/24"
    #     },
    #     {
    #       user_defined_code = "inbound-internal",
    #       address_space     = "10.91.3.0/24"
    #     }
    #   ]
    # }
  ]
}