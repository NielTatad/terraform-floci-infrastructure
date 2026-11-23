variable "name" {
  description = "Name of the Application Load Balancer."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to create the ALB in."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs the ALB is attached to."
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group ID for the ALB."
  type        = string
}

variable "enable_deletion_protection" {
  description = "Prevent accidental deletion of the ALB."
  type        = bool
  default     = false
}

variable "target_port" {
  description = "Port the target group forwards traffic to."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path for the target group health check."
  type        = string
  default     = "/healthz"
}

variable "tags" {
  description = "Tags applied to all ALB resources."
  type        = map(string)
  default     = {}
}
