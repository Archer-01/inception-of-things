terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    vercel = {
      source  = "vercel/vercel"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket         = "inception-of-things-terraform-state"
    key            = "hls-origin/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "inception-of-things-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
}

provider "vercel" {}
