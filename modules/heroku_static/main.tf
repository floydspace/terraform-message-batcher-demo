resource "heroku_app" "default" {
  name   = var.name
  region = "eu"
}

resource "heroku_build" "default" {
  app        = heroku_app.default.id
  buildpacks = ["https://github.com/heroku/heroku-buildpack-static.git"]

  source = {
    path = var.folder
  }
}
