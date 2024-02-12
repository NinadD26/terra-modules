terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
  access_key = "AKIAZKGM5DUWG32M45PE"
  secret_key = "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"
}
