variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.31"
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role the EKS control plane assumes."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs (public + private) for the EKS cluster."
  type        = list(string)
}

variable "cluster_sg_id" {
  description = "ID of the EKS cluster security group."
  type        = string
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint (accessible within VPC)."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint."
  type        = bool
  default     = true
}

variable "enabled_log_types" {
  description = "EKS control plane log types to enable."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "tags" {
  description = "Tags applied to the EKS cluster."
  type        = map(string)
  default     = {}
}
