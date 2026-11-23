output "nodegroup_id" {
  description = "ID of the EKS managed node group."
  value       = aws_eks_node_group.this.id
}

output "nodegroup_arn" {
  description = "ARN of the EKS managed node group."
  value       = aws_eks_node_group.this.arn
}

output "nodegroup_name" {
  description = "Name of the EKS managed node group."
  value       = aws_eks_node_group.this.node_group_name
}

output "nodegroup_status" {
  description = "Status of the EKS managed node group."
  value       = aws_eks_node_group.this.status
}
