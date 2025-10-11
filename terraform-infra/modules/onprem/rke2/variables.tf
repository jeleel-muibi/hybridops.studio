variable "cluster_name" { type = string }
variable "node_count"   { type = number default = 3 }
variable "tags"         { type = map(string) default = {} }
