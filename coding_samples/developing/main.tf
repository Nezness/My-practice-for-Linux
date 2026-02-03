#-------------------------
# Terraform configuration
#-------------------------
terraform {
  required_version = ">=1.14"
  required_providers {
    aws = {
      version = "~>6.0"
    }
  }
}

#-------------------------
# Provider
#-------------------------
provider "aws" {
  profile = "terraform_pub"
  region  = "ap-northeast-1"
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

