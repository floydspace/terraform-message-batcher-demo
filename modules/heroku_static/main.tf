provider "heroku" {}
provider "local" {}

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

  depends_on = [local_file.default]
}

resource "local_file" "default" {
  content = jsonencode({
    clean_urls = true
    routes = {
      "/static/*" = "/static/"
      "/**"       = "index.html"
    }
  })
  filename = "${var.folder}/static.json"
}
