
packer {
  required_plugins { googlecompute = { version = ">= 1.1.1" source = "github.com/hashicorp/googlecompute" } }
}
variable "project_id" {}
variable "zone" { default = "europe-west2-a" }
variable "image_family" { default = "control-node" }
variable "image_name" { default = "control-node-latest" }
source "googlecompute" "control_node" {
  project_id = var.project_id
  zone = var.zone
  source_image_family = "ubuntu-2204-lts"
  ssh_username = "packer"
  image_name = var.image_name
  image_family = var.image_family
  machine_type = "e2-standard-4"
}
build {
  name = "control-node-gcp-image"
  sources = ["source.googlecompute.control_node"]
  provisioner "file" { source = "../scripts/install_tools.sh" destination = "/tmp/install_tools.sh" }
  provisioner "shell" { inline = ["chmod +x /tmp/install_tools.sh","sudo /tmp/install_tools.sh"] }
}
