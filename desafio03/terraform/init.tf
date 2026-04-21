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
}
