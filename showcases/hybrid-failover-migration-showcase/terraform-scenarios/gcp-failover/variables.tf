
variable "prefix" { type = string default = "ctrl-failover" }
variable "project_id" { type = string }
variable "region" { type = string default = "europe-west2" }
variable "zone" { type = string default = "europe-west2-a" }
variable "image" { type = string } # e.g., control-node-latest
variable "machine_type" { type = string default = "e2-standard-4" }
variable "admin_username" { type = string default = "gcpuser" }
variable "ssh_public_key" { type = string }
