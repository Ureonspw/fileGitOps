terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

resource "null_resource" "creation_vagrant_env" {
  provisioner "local-exec" {
    command = "bash ../scripts/creationlocal.sh"
  }
}
