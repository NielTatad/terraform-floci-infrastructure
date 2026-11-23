# ---------------------------------------------------------------------------
# Floci / provider
# ---------------------------------------------------------------------------
variable "floci_endpoint" {
  description = "HTTP endpoint of the local Floci AWS emulator."
  type        = string
  default     = "http://localhost:4566"
}

variable "aws_region" {
  description = "AWS region to report to the provider."
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key" {
  description = "Dummy AWS access key for Floci."
  type        = string
  default     = "test"
  sensitive   = true
}

variable "aws_secret_key" {
  description = "Dummy AWS secret key for Floci."
  type        = string
  default     = "test"
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Environment metadata
# ---------------------------------------------------------------------------
variable "environment" {
  description = "Logical environment name applied as a tag to all resources."
  type        = string
  default     = "local"
}

variable "project" {
  description = "Project name applied as a tag to all resources."
  type        = string
  default     = "floci-eks"
}

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the EKS VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "Availability zones for subnet distribution."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway for private subnet outbound access."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# EKS
# ---------------------------------------------------------------------------
variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "floci-eks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.31"
}

# ---------------------------------------------------------------------------
# Node Group
# ---------------------------------------------------------------------------
variable "nodegroup_name" {
  description = "Name of the managed node group."
  type        = string
  default     = "floci-eks-nodes"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}

variable "node_instance_types" {
  description = "EC2 instance types for worker nodes."
  type        = list(string)
  default     = ["t3.medium"]
}

# ---------------------------------------------------------------------------
# ECR
# ---------------------------------------------------------------------------
variable "ecr_repository_name" {
  description = "Name of the ECR repository."
  type        = string
  default     = "floci-eks-app"
}

# ---------------------------------------------------------------------------
# CloudWatch
# ---------------------------------------------------------------------------
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch log events."
  type        = number
  default     = 7
}
