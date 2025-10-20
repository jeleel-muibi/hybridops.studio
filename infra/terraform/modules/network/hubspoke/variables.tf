variable "hub_cidr"     { type = string }
variable "spoke_cidrs"  { type = list(string) }
variable "provider"     { type = string  description = "azure|gcp" }
variable "tags"         { type = map(string) default = {} }
