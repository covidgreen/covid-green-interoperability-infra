# #########################################
# AWS VPC module
#   - check https://github.com/terraform-aws-modules/terraform-aws-vpc
# #########################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.44.0"

  name = module.labels.id
  cidr = var.vpc_cidr

  # PENDING: See the comment in the var - lets get rid of this by increasing the EIP from 5 -> 10 on qa, so we do not need this
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count_to_use)

  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  public_subnets  = slice(var.public_subnets_cidr, 0, var.az_count_to_use)
  private_subnets = slice(var.private_subnets_cidr, 0, var.az_count_to_use)
  intra_subnets   = slice(var.intra_subnets_cidr, 0, var.az_count_to_use)

  assign_ipv6_address_on_creation = false
  enable_ipv6                     = true
  public_subnet_ipv6_prefixes     = slice([0, 1, 2], 0, var.az_count_to_use)

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    Name = "${module.labels.id}-public"
  }
  public_route_table_tags = {
    Name = "${module.labels.id}-public"
  }
  private_subnet_tags = {
    Name = "${module.labels.id}-private"
  }
  private_route_table_tags = {
    Name = "${module.labels.id}-private"
  }
  intra_subnet_tags = {
    Name = "${module.labels.id}-intra"
  }
  intra_route_table_tags = {
    Name = "${module.labels.id}-intra"
  }

  enable_s3_endpoint = true

  enable_ssm_endpoint              = true
  ssm_endpoint_private_dns_enabled = true
  ssm_endpoint_security_group_ids  = [aws_security_group.vpce.id]

  enable_sns_endpoint              = true
  sns_endpoint_private_dns_enabled = true
  sns_endpoint_security_group_ids  = [aws_security_group.vpce.id]

  enable_ecr_dkr_endpoint              = true
  ecr_dkr_endpoint_private_dns_enabled = true
  ecr_dkr_endpoint_security_group_ids  = [aws_security_group.vpce.id]

  enable_secretsmanager_endpoint              = true
  secretsmanager_endpoint_private_dns_enabled = true
  secretsmanager_endpoint_security_group_ids  = [aws_security_group.vpce.id]

  enable_logs_endpoint              = true
  logs_endpoint_private_dns_enabled = true
  logs_endpoint_security_group_ids  = [aws_security_group.vpce.id]

  enable_monitoring_endpoint              = true
  monitoring_endpoint_private_dns_enabled = true
  monitoring_endpoint_security_group_ids  = [aws_security_group.vpce.id]

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  nat_gateway_tags = {
    Name = module.labels.id
  }

  tags = module.labels.tags
}

resource "aws_security_group" "vpce" {
  name   = "${module.labels.id}-endpoints"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  tags = module.labels.tags
}
