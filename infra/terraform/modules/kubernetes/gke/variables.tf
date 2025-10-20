variable "name"       { type = string }
variable "region"     { type = string }
variable "node_count" { type = number  default = 3 }
variable "tags"       { type = map(string) default = {} }
