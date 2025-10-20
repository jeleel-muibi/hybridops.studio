
packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "alpine" {
  image  = "alpine:latest"
  commit = false
}

build {
  name    = "docker-alpine-validate"
  sources = ["source.docker.alpine"]
}
