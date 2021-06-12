terraform {
  required_providers {
    heroku = {
      source  = "heroku/heroku"
      version = "3.2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }
  }
}
