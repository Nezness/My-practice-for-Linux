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
  profile = var.profile
  region  = var.region
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

variable "profile" {
  type = string
}

variable "region" {
  type = string
}