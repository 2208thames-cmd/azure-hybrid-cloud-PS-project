import {
  to = module.network.azurerm_vpn_gateway.main[0]
  id = "/subscriptions/2432a69d-15e9-46e8-ad46-0a7c9ec9a704/resourceGroups/rg-hybridcloud-dev/providers/Microsoft.Network/vpnGateways/vpngw-hybridcloud"
}

import {
  to = module.network.azurerm_point_to_site_vpn_gateway.main[0]
  id = "/subscriptions/2432a69d-15e9-46e8-ad46-0a7c9ec9a704/resourceGroups/rg-hybridcloud-dev/providers/Microsoft.Network/p2sVpnGateways/p2svpngw-hybridcloud"
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.environment}"
  location = var.location
  tags     = var.tags
}

module "network" {
  source              = "../../modules/network"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  project             = var.project
  tags                = var.tags
  enable_p2s_vpn      = true
}

module "monitoring" {
  source              = "../../modules/monitoring"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  project             = var.project
  environment         = var.environment
  tags                = var.tags
}

module "governance" {
  source            = "../../modules/governance"
  resource_group_id = azurerm_resource_group.main.id
  environment       = var.environment
}

module "identity" {
  source              = "../../modules/identity"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  project             = var.project
  environment         = var.environment
  tags                = var.tags
}

module "backup" {
  source              = "../../modules/backup"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  project             = var.project
  environment         = var.environment
  tags                = var.tags
}

#
