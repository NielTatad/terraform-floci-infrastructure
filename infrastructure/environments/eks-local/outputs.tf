# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------
output "vpc_id" {
  description = "ID of the EKS VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs."
  value       = module.vpc.nat_gateway_ids
}

# ---------------------------------------------------------------------------
# Security Groups
# ---------------------------------------------------------------------------
output "cluster_sg_id" {
  description = "EKS cluster control-plane security group ID."
  value       = module.security_groups.cluster_sg_id
}

output "nodes_sg_id" {
  description = "EKS worker node security group ID."
  value       = module.security_groups.nodes_sg_id
}

# ---------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------
output "cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role."
  value       = module.iam_eks.cluster_role_arn
}

output "node_role_arn" {
  description = "ARN of the EKS worker node IAM role."
  value       = module.iam_eks.node_role_arn
}

# ---------------------------------------------------------------------------
# EKS Cluster
# ---------------------------------------------------------------------------
output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint (Floci stub — not a real Kubernetes API)."
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster."
  value       = module.eks_cluster.cluster_version
}

# ---------------------------------------------------------------------------
# Node Group
# ---------------------------------------------------------------------------
output "nodegroup_name" {
  description = "EKS managed node group name."
  value       = module.eks_nodegroup.nodegroup_name
}

output "nodegroup_status" {
  description = "EKS managed node group status."
  value       = module.eks_nodegroup.nodegroup_status
}

# ---------------------------------------------------------------------------
# ECR
# ---------------------------------------------------------------------------
output "ecr_repository_url" {
  description = "ECR repository URL. Use as the Docker image registry."
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name."
  value       = module.ecr.repository_name
}

# ---------------------------------------------------------------------------
# ALB
# ---------------------------------------------------------------------------
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = module.alb.alb_dns_name
}

output "alb_target_group_arn" {
  description = "ARN of the ALB target group."
  value       = module.alb.target_group_arn
}

# ---------------------------------------------------------------------------
# CloudWatch
# ---------------------------------------------------------------------------
output "eks_cluster_log_group" {
  description = "CloudWatch log group for EKS control plane."
  value       = module.cloudwatch_logs.cluster_log_group_name
}

# ---------------------------------------------------------------------------
# Floci endpoint (convenience reminder)
# ---------------------------------------------------------------------------
output "floci_endpoint" {
  description = "Floci endpoint all resources are provisioned against."
  value       = var.floci_endpoint
}
