# #########################################
# Backend config
# #########################################
terraform {
  required_version = ">= 0.12.28"
  backend "s3" {}
}

# #########################################
# AWS provider
# #########################################
provider "aws" {
  version = "2.68.0"
  region  = var.aws_region
  profile = var.profile
}

provider "aws" {
  version = "2.68.0"
  alias   = "us"
  region  = "us-east-1"
  profile = var.profile
}

# Provider based on main but using us_east_1 as region
# Will use this if creating a TLS certificate in us-east-1 region as required by CloudFront Edge used by the APIGateway
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = var.profile
}

# DNS provider
# Will use this if managing DNS, in some cases the Route53 zones are managed on a different account
provider "aws" {
  version = "2.68.0"
  alias   = "dns"
  region  = var.aws_region
  profile = var.dns_profile
}

# #########################################
# Other providers
# #########################################
provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

provider "random" {
  version = "~> 2.0"
}

provider "archive" {
  version = "~> 1.3.0"
}

# #########################################
# Data
# #########################################
data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}
