terraform {
  required_version = ">= 1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.13.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }

  backend "s3" {
    bucket = "mcomputing-rs-circuit-breakers2"
    key    = "terraform.tfstate"
    region = "eu-west-2"
  }
}
