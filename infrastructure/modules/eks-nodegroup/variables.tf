variable "cluster_name" {
  description = "Name of the EKS cluster this node group belongs to."
  type        = string
}

variable "nodegroup_name" {
  description = "Name of the managed node group."
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role that worker nodes assume."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs where worker nodes are launched."
  type        = list(string)
}

variable "desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}

variable "instance_types" {
  description = "EC2 instance types for worker nodes."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "ami_type" {
  description = "AMI type for worker nodes. AL2_x86_64 is the standard Amazon Linux 2 AMI."
  type        = string
  default     = "AL2_x86_64"
}

variable "capacity_type" {
  description = "Capacity type: ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "disk_size" {
  description = "Disk size in GiB for worker node root volumes."
  type        = number
  default     = 20
}

variable "tags" {
  description = "Tags applied to the node group."
  type        = map(string)
  default     = {}
}
