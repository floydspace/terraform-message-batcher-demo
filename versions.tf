terraform {
  backend "s3" {
    bucket         = "bgen-terraform-backend"
    key            = "message-batcher-dev/terraform.tfstate"
    dynamodb_table = "bgen-terraform-backend"
    region         = "eu-north-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.44.0"
    }
  }
}
