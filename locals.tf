# #########################################
# Locals
# #########################################
locals {
  # Based on flag
  bastion_enabled_count = var.bastion_enabled ? 1 : 0

  # Will be used as a prefix for AWS parameters and secrets
  config_var_prefix = "${module.labels.id}-"

  # Based on flag
  enable_dns_count = var.enable_dns ? 1 : 0

  # RDS enhanced monitoring count
  rds_enhanced_monitoring_enabled_count = var.rds_enhanced_monitoring_interval > 0 ? 1 : 0

  # Need to only create one of these for an account/region
  # PENDING: Going to set to 0 for dev, assuming qa and prod use a different AWS org so can create
  gateway_api_account_count = 0
}
