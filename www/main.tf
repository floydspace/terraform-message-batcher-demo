provider "aws" {
  region = var.region
}

locals {
  service_name = "${local.aws_default_tags.Space}-${local.aws_default_tags.Name}"
  aws_default_tags = {
    Space = "bgen"
    Name  = "message-batcher-website"
    Stage = var.stage
  }
}

module "website_static" {
  source = "../modules/aws_s3_static"

  name   = "${local.service_name}-site-${var.stage}"
  folder = "${path.cwd}/build"
}

# module "website_static" {
#   source = "./modules/heroku_static"

#   name   = "${local.service_name}-site-${var.stage}"
#   folder = "${path.cwd}/build"
# }