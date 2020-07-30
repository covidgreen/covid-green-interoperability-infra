# #########################################
# Parameters
# #########################################
resource "aws_ssm_parameter" "batch_size" {
  overwrite = true
  name      = "${local.config_var_prefix}batch_size"
  type      = "String"
  value     = var.batch_size
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "batch_url" {
  overwrite = true
  name      = "${local.config_var_prefix}batch_url"
  type      = "String"
  value     = aws_sqs_queue.batch.id
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "cors_origin" {
  overwrite = true
  name      = "${local.config_var_prefix}cors_origin"
  type      = "String"
  value     = var.interop_cors_origin
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "db_database" {
  overwrite = true
  name      = "${local.config_var_prefix}db_database"
  type      = "String"
  value     = var.rds_db_name
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "db_host" {
  overwrite = true
  name      = "${local.config_var_prefix}db_host"
  type      = "String"
  value     = module.rds_cluster_aurora_postgres.endpoint
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "db_port" {
  overwrite = true
  name      = "${local.config_var_prefix}db_port"
  type      = "String"
  value     = 5432
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "db_reader_host" {
  overwrite = true
  name      = "${local.config_var_prefix}db_reader_host"
  type      = "String"
  value     = module.rds_cluster_aurora_postgres.reader_endpoint
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "db_ssl" {
  overwrite = true
  name      = "${local.config_var_prefix}db_ssl"
  type      = "String"
  value     = "true"
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "log_level" {
  overwrite = true
  name      = "${local.config_var_prefix}log_level"
  type      = "String"
  value     = var.log_level
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "interop_host" {
  overwrite = true
  name      = "${local.config_var_prefix}interop_host"
  type      = "String"
  value     = "0.0.0.0"
  tags      = module.labels.tags
}

resource "aws_ssm_parameter" "interop_port" {
  overwrite = true
  name      = "${local.config_var_prefix}interop_port"
  type      = "String"
  value     = var.interop_listening_port
  tags      = module.labels.tags
}
