variable "prefix" {
  description = "Name prefix for created resources"
  type        = string
}

variable "region" {
  description = "Deployment region"
  type        = string
}

variable "burst" {
  description = "Whether to enable burst/scale-out"
  type        = bool
  default     = false
}

variable "node_count" {
  description = "Initial/desired node count"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Resource tags/labels"
  type        = map(string)
  default     = {}
}
