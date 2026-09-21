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

# --- Remaining modules will be wired in here as we build each piece ---
#
# module "governance" {
#   source = "../../modules/governance"
# }
#
# module "identity" {
#   source = "../../modules/identity"
# }
#
# module "backup" {
#   source = "../../modules/backup"
# }
