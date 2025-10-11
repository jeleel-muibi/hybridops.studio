variable "azure_subscription_id" { type = string }
variable "azure_tenant_id"       { type = string }
variable "kube_host"             { type = string }
variable "kube_ca"               { type = string }
variable "kube_token"            { type = string }
variable "location"              { type = string  default = "westeurope" }
