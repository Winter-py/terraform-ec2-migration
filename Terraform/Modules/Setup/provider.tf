terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.66"
    }
  }

   required_version = ">= 1.2.0"
}


provider "aws" {
  alias  = "Ireland"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "London"
  region = "eu-west-2"
}

provider "aws" {
  alias  = "US West"
  region = "us-west-1"
}