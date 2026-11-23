variable "name" {
  description = "Name prefix for all security groups."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to create security groups in."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC, used for intra-cluster rules."
  type        = string
}

variable "tags" {
  description = "Tags applied to all security groups."
  type        = map(string)
  default     = {}
}
