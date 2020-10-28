# #########################################
# Misc
# #########################################
variable "namespace" {}
variable "full_name" {}
variable "environment" {}
variable "profile" {}
variable "dns_profile" {}
variable "aws_region" {}

# #########################################
# Admins role
# #########################################
variable "admins_role_require_mfa" {
  # Turning this on is fine with the AWS CLI but is tricky with TF and we have multiple accounts in play in some envs
  description = "Require MFA for assuming the admins IAM role"
  default     = false
}

# #########################################
# DNS and certificates
# #########################################
variable "enable_certificates" {
  default = true
}
variable "enable_dns" {
  default = true
}

# #########################################
# Monitoring
# #########################################
variable "enable_monitoring" {
  default = false
}
variable "slack_webhook_url" {
  default = ""
}
variable "slack_username" {
  default = ""
}
variable "threshold_5xx" {
  default = 1
}
variable "period_5xx" {
  default = 60
}
variable "threshold_4xx" {
  default = 25
}
variable "period_4xx" {
  default = 60
}
variable "threshold_latency" {
  default = 500
}
variable "period_latency" {
  default = 300
}

# #########################################
# Networking
# #########################################
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
variable "private_subnets_cidr" {
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
variable "public_subnets_cidr" {
  default = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}
variable "database_subnets_cidr" {
  default = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}
variable "intra_subnets_cidr" {
  default = ["10.0.31.0/24", "10.0.32.0/24", "10.0.33.0/24"]
}
# THE HORROR - Should just increase the qa limit to get rid of this
variable "az_count_to_use" {
  default = 3
}

# #########################################
# RDS Settings
# #########################################
variable "rds_backup_retention" {
  default = 14
}
variable "rds_cluster_family" {
  default = "aurora-postgresql11"
}
variable "rds_cluster_size" {
  default = 1
}
variable "rds_db_name" {
  default = "interop"
}
# Enhanced monitoring metrics, the default is 0 which is disabled. Valid Values: 0, 1, 5, 10, 15, 30, 60. These are in seconds.
variable "rds_enhanced_monitoring_interval" {
  default = 0
}
variable "rds_instance_type" {
  default = "db.t3.medium"
}

# #########################################
# ECR Settings
# #########################################
variable "default_ecr_max_image_count" {
  default = 30
}

# #########################################
# R53 Settings
# #########################################
variable "interop_dns" {}
variable "route53_zone" {}
variable "wildcard_domain" {
  description = "DNS wildcard domain"
}

# #########################################
# Bastion
# #########################################
variable "bastion_enabled" {
  default = true
}

# #########################################
# Interop & Lambda - Settings & Env vars
# #########################################
variable "interop_listening_port" {
  default = 5000
}
variable "interop_listening_protocol" {
  default = "HTTP"
}
variable "interop_cors_origin" {
  default = "*"
}
variable "health_check_path" {
  default = "/healthcheck"
}
variable "health_check_matcher" {
  default = "200"
}
variable "health_check_interval" {
  default = 10
}
variable "health_check_timeout" {
  default = 5
}
variable "health_check_healthy_threshold" {
  default = 3
}
variable "health_check_unhealthy_threshold" {
  default = 2
}
variable "interop_service_desired_count" {}
variable "interop_services_task_cpu" {
  default = 256
}
variable "interop_services_task_memory" {
  default = 512
}
variable "interop_ecs_autoscale_min_instances" {
  default = 5
}
variable "interop_ecs_autoscale_max_instances" {
  default = 20
}
variable "interop_cpu_high_threshold" {
  default = 15
}
variable "interop_cpu_low_threshold" {
  default = 10
}
variable "interop_mem_high_threshold" {
  default = 25
}
variable "interop_mem_low_threshold" {
  default = 15
}
variable "log_level" {}
variable "logs_retention_days" {}
variable "batch_size" {
  default = "1000"
}
variable "batch_schedule" {}
