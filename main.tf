##-----------------------------------------------------------------------------
## Labels module callled that will be used for naming and tags.
##-----------------------------------------------------------------------------
module "labels" {
  source      = "cypik/labels/azure"
  version     = "1.0.2"
  name        = var.name
  environment = var.environment
  managedby   = var.managedby
  label_order = var.label_order
  repository  = var.repository
  extra_tags  = var.extra_tags
}

resource "azurerm_subnet" "subnet" {
  count                                         = var.enable && var.specific_name_subnet == false ? length(var.subnet_names) : 0
  name                                          = "${var.name}-${var.subnet_names[count.index]}"
  resource_group_name                           = var.resource_group_name
  address_prefixes                              = [var.subnet_prefixes[count.index]]
  virtual_network_name                          = var.virtual_network_name
  default_outbound_access_enabled               = var.default_outbound_access_enabled
  private_endpoint_network_policies             = lookup(var.subnet_enforce_private_link_endpoint_network_policies, var.subnet_names[count.index], false) ? "Enabled" : "Disabled"
  private_link_service_network_policies_enabled = var.subnet_enforce_private_link_service_network_policies

  dynamic "delegation" {
    for_each = var.delegation
    content {
      name = delegation.key
      dynamic "service_delegation" {
        for_each = toset(delegation.value)
        content {
          name    = service_delegation.value.name
          actions = service_delegation.value.actions
        }
      }
    }
  }
}

resource "azurerm_subnet" "specific_subnet" {
  count                                         = var.enable && var.specific_name_subnet == true ? 1 : 0
  name                                          = var.specific_subnet_names
  resource_group_name                           = var.resource_group_name
  address_prefixes                              = [var.subnet_prefixes[count.index]]
  virtual_network_name                          = var.virtual_network_name
  private_endpoint_network_policies             = lookup(var.subnet_enforce_private_link_endpoint_network_policies, var.specific_subnet_names, false) ? "Enabled" : "Disabled"
  service_endpoints                             = var.service_endpoints
  private_link_service_network_policies_enabled = var.subnet_enforce_private_link_service_network_policies

  dynamic "delegation" {
    for_each = var.delegation
    content {
      name = delegation.key
      dynamic "service_delegation" {
        for_each = toset(delegation.value)
        content {
          name    = service_delegation.value.name
          actions = service_delegation.value.actions
        }
      }
    }
  }
}

resource "azurerm_public_ip" "pip" {
  count               = var.create_nat_gateway ? 1 : 0
  allocation_method   = "Static"
  location            = var.location
  name                = format("%s-nat-gateway-ip", module.labels.id)
  resource_group_name = var.resource_group_name
  zones               = var.public_ip_zones
  sku                 = "Standard"

  tags = module.labels.tags
}

resource "azurerm_nat_gateway" "natgw" {
  count                   = var.create_nat_gateway ? 1 : 0
  location                = var.location
  name                    = format("%s-nat-gateway", module.labels.id)
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = var.nat_gateway_idle_timeout

  tags = module.labels.tags
}

resource "azurerm_nat_gateway_public_ip_association" "pip_assoc" {
  count                = var.create_nat_gateway ? 1 : 0
  nat_gateway_id       = join("", azurerm_nat_gateway.natgw[*].id)
  public_ip_address_id = azurerm_public_ip.pip[0].id
}

resource "azurerm_subnet_nat_gateway_association" "subnet_assoc" {
  count          = var.create_nat_gateway ? (var.specific_name_subnet == false ? length(azurerm_subnet.subnet[*].id) : length(azurerm_subnet.specific_subnet[*].id)) : 0
  nat_gateway_id = join("", azurerm_nat_gateway.natgw[*].id)
  subnet_id      = var.specific_name_subnet == false ? element(azurerm_subnet.subnet[*].id, count.index) : element(azurerm_subnet.specific_subnet[*].id, count.index)
}

#Route Table
resource "azurerm_route_table" "rt" {
  count               = var.enable && var.enable_route_table ? 1 : 0
  name                = var.route_table_name == null ? format("%s-route-table", module.labels.id) : format("%s-%s-route-table", module.labels.id, var.route_table_name)
  location            = var.location
  resource_group_name = var.resource_group_name
  dynamic "route" {
    for_each = var.routes
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = lookup(route.value, "next_hop_in_ip_address", null)
    }
  }
  bgp_route_propagation_enabled = var.bgp_route_propagation_enabled
  tags                          = module.labels.tags
}

resource "azurerm_subnet_route_table_association" "main" {
  count          = var.enable && var.enable_route_table && var.specific_name_subnet == false ? length(var.subnet_prefixes) : 0
  subnet_id      = element(azurerm_subnet.subnet[*].id, count.index)
  route_table_id = join("", azurerm_route_table.rt[*].id)
}

resource "azurerm_subnet_route_table_association" "main2" {
  count          = var.enable && var.enable_route_table && var.specific_name_subnet ? length(var.subnet_prefixes) : 0
  subnet_id      = element(azurerm_subnet.specific_subnet[*].id, count.index)
  route_table_id = join("", azurerm_route_table.rt[*].id)
}
