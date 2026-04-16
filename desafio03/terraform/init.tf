terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.14.7"
}

provider "aws" {
  region  = "us-east-1"
  profile = "awscli"

  assume_role {
    role_arn     = "arn:aws:iam::794038217446:role/role-time-dev"
    session_name = "terraform-session"
  }
}
