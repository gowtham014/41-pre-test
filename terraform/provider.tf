terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20"
    }
  }
  # backend "s3" {  }
}


provider "aws" {
  region = "ap-south-1"
}

