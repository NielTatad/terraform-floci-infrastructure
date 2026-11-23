variable "name" {
  description = "Name prefix for all IAM roles and policies."
  type        = string
}

variable "tags" {
  description = "Tags applied to all IAM resources."
  type        = map(string)
  default     = {}
}
