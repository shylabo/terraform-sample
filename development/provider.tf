provider "aws" {
  version = "2.20.0"
  region  = data.aws_region.current.name
}

provider "github" {
  organization = "shylabo"
}

terraform {
  required_version = "0.12.5"
  # required_providers {
  #   aws = {
  #     source  = "hashicorp/aws"
  #     version = "~> 2.20.0"
  #   }
  # }
}
