provider "azurerm" {
  skip_provider_registration = "true"

  features {}
}

##-----------------------------------------------------------------------------
## Resource group in which all resources will be deployed.
##-----------------------------------------------------------------------------
module "resource_group" {
  source      = "git::git@github.com:opz0/terraform-azure-resource-group.git?ref=master"
  name        = "app"
  environment = "test"
  location    = "North Europe"
}

##-----------------------------------------------------------------------------
## Virtual Network module call.
##-----------------------------------------------------------------------------
module "vnet" {
  source              = "git::git@github.com:opz0/terraform-azure-vnet.git?ref=master"
  name                = "app"
  environment         = "test"
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  address_space       = "10.0.0.0/16"
}

module "name_specific_subnet" {
  source = "../.."

  name                 = "app"
  environment          = "test"
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  virtual_network_name = join("", module.vnet.vnet_name)

  #subnet
  specific_name_subnet  = true
  specific_subnet_names = "SpecificSubnet"
  subnet_prefixes       = ["10.0.1.0/24"]

  # route_table
  enable_route_table = true
  route_table_name   = "name_specific_subnet"
  routes = [
    {
      name           = "rt-test"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
  ]
}
