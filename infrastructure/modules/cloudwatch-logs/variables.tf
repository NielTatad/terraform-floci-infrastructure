variable "cluster_name" {
  description = "Name of the EKS cluster, used to construct log group paths."
  type        = string
}

variable "retention_days" {
  description = "Number of days to retain log events."
  type        = number
  default     = 7

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365], var.retention_days)
    error_message = "retention_days must be a valid CloudWatch value: 0,1,3,5,7,14,30,60,90,120,150,180,365."
  }
}

variable "tags" {
  description = "Tags applied to all log groups."
  type        = map(string)
  default     = {}
}
