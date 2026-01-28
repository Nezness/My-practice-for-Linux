#-------------------------
# Terraform configuration
#-------------------------
terraform {
  required_version = ">=1.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket  = "Put your bucket name" # Notioce
    key     = "${var.project}-${var.environment}.tfstate"
    region  = "ap-northeast-1"
    profile = "terraform"
  }
}

#-------------------------
# Provider
#-------------------------
provider "aws" {
  profile = "terraform"
  region  = "ap-northeast-1"
}

provider "aws" {
  alias   = "singapole"
  profile = "terraform"
  region  = "ap-southeast-1"
}

#-------------------------
# Variables
#-------------------------
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "domain" {
  type = string

}

