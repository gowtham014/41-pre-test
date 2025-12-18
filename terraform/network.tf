


#  Locals for subnet CIDR blocks
locals {
  # ECS specific subnet CIDR blocks
  ecs_public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  ecs_private_subnet_cidrs = ["10.0.5.0/24", "10.0.6.0/24"]
  ecs_azs                  = ["ap-south-1a", "ap-south-1b"]

  #  Lambda specific subnet CIDR blocks
  lambda_public_subnet_cidrs  = ["10.0.3.0/24", "10.0.4.0/24"]
  lambda_private_subnet_cidrs = ["10.0.7.0/24", "10.0.8.0/24"]
  lambda_azs                  = ["ap-south-1a", "ap-south-1b"]


  #  DYNAMIC selection of resources creation
  selected_public_subnet_cidrs = concat(
    var.deploy_ecs ? local.ecs_public_subnet_cidrs : [],
    var.deploy_lambda ? local.lambda_public_subnet_cidrs : []
  )

  selected_private_subnet_cidrs = concat(
    var.deploy_ecs ? local.ecs_private_subnet_cidrs : [],
    var.deploy_lambda ? local.lambda_private_subnet_cidrs : []
  )

  selected_azs = concat(
    var.deploy_ecs ? local.ecs_azs : [],
    var.deploy_lambda ? local.lambda_azs : []
  )
}

# Creation of vpc and subnets

module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  version         = "6.5.1"
  name            = "pre-test-vpc"
  cidr            = "10.0.0.0/16"
  azs             = local.selected_azs
  public_subnets  = local.selected_public_subnet_cidrs
  private_subnets = local.selected_private_subnet_cidrs

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  single_nat_gateway   = true

  public_subnet_tags = {
    Tier     = "Public"
    resource = var.deploy_ecs && var.deploy_lambda ? "Hybrid" : (var.deploy_ecs ? "ECS-Only" : "Lambda-Only")
  }

  private_subnet_tags = {
    Tier     = "Private"
    resource = var.deploy_ecs && var.deploy_lambda ? "Hybrid" : (var.deploy_ecs ? "ECS-Only" : "Lambda-Only")
  }

  tags = {
    scenario = var.deploy_ecs && var.deploy_lambda ? "Hybrid" : (var.deploy_ecs ? "ECS-Only" : "Lambda-Only")
    project  = "Pretest-Particle41"
  }
}



