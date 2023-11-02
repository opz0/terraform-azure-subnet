# terraform-azure-subnet
# Terraform Azure vnet and Subnet Modules

## Table of Contents

- [Introduction](#introduction)
- [Usage](#usage)
- [Module Inputs](#module-inputs)
- [Module Outputs](#module-outputs)
- [License](#license)

## Introduction
This repository contains Terraform code for deploying Azure resources using modules. This README provides an overview of the code and how to use it.

## Usage
To use this module, include it in your Terraform configuration file and provide the required input variables. Below is an example of how to use the module:

# default-subnet

```hcl
module "subnet" {
  source = "git::https://github.com/opz0/terraform-azure-subnet.git?ref=v1.0.0"

  name                 = "app"
  environment          = "test"
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  virtual_network_name = module.vnet.vnet_name[0]

  #subnet
  subnet_names    = ["subnet1"]
  subnet_prefixes = ["10.0.1.0/24"]

  # route_table
  enable_route_table = true
  route_table_name   = "default_subnet"
  routes = [
    {
      name           = "rt-test"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
  ]
}
```
You can customize the input variables according to your specific requirements.

# name-specific-subnet

```hcl
module "name_specific_subnet" {
  source = "git::https://github.com/opz0/terraform-azure-subnet.git?ref=v1.0.0"

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
```
You can customize the input variables according to your specific requirements.

# nat-gateway-subnet

```hcl
module "subnet" {
  source = "git::https://github.com/opz0/terraform-azure-subnet.git?ref=v1.0.0"

  name        = "app"
  environment = "test"

  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  virtual_network_name = module.vnet.vnet_name

  #subnet
  create_nat_gateway = true
  subnet_names       = ["subnet1", "subnet2"]
  subnet_prefixes    = ["10.0.1.0/24", "10.0.2.0/24"]

  # route_table
  enable_route_table = true
  route_table_name   = "nat_gateway"
  routes = [
    {
      name           = "rt-test"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
  ]
}
```
You can customize the input variables according to your specific requirements.

## Module Inputs
The following are the inputs for the modules used in this Terraform code:

- 'name': The name of the subnet.
- 'environment': The environment in which the subnet is deployed.
- 'resource_group_name': The name of the resource group where the subnet is created.
- 'location': The Azure region where the subnet is created.
- 'virtual_network_name': The name of the virtual network to which the subnet is attached.
- 'subnet_names': An array of subnet names.
- 'specific_subnet_names' (Optional): The name of the subnet when `specific_name_subnet` is set to `true`.
- 'specific_name_subnet' (Optional): Set this to `true` if you want to specify a custom subnet name. If set to `false`, a default subnet name will be generated.
- 'subnet_prefixes'(Required): List of IP address prefixes for the subnet (e.g., ["10.0.1.0/24"]).
- 'create_nat_gateway' (bool): Indicates whether to create a NAT gateway.
- 'enable_route_table'(Optional): Set this to true if you want to associate a route table with the subnet. If set to false, no route table will be associated.
- 'route_table_name'(Optional): The name of the route table when `enable_route_table` is set to `true`.
- 'routes'(Optional): A list of route entries to associate with the route table. Each route should have the following attributes:

   `name`: A unique name for the route.

   `address_prefix`: The destination IP address prefix for the route (e.g., "0.0.0.0/0").

   `next_hop_type`: The type of next hop for the route (e.g., "Internet").

## Module Outputs
This code provides module outputs that can be referenced in other parts of your Terraform configuration. For example, you can reference `module.resource_group.resource_group_name` to get the resource group name.

## Examples
For detailed examples on how to use this module, please refer to the 'examples' directory within this repository.

## Author
Your Name Replace '[License Name]' and '[Your Name]' with the appropriate license and your information. Feel free to expand this README with additional details or usage instructions as needed for your specific use case.

## License
This project is licensed under the MIT License - see the [LICENSE](https://github.com/opz0/terraform-azure-subnet/blob/readme/LICENSE) file for details.
