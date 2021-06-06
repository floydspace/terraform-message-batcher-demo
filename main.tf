locals {
  service_name = "${local.aws_default_tags.Space}-${local.aws_default_tags.Name}"
  aws_default_tags = {
    Space = "bgen"
    Name  = "message-batcher"
    Stage = var.stage
  }
}

provider "aws" {
  profile = "default"
  region  = var.region
}
