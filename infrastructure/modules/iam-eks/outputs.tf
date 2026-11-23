output "cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role."
  value       = aws_iam_role.eks_cluster.arn
}

output "cluster_role_name" {
  description = "Name of the EKS cluster IAM role."
  value       = aws_iam_role.eks_cluster.name
}

output "node_role_arn" {
  description = "ARN of the EKS worker node IAM role."
  value       = aws_iam_role.eks_nodes.arn
}

output "node_role_name" {
  description = "Name of the EKS worker node IAM role."
  value       = aws_iam_role.eks_nodes.name
}

output "node_instance_profile_name" {
  description = "Name of the EC2 instance profile for worker nodes."
  value       = aws_iam_instance_profile.eks_nodes.name
}

output "node_instance_profile_arn" {
  description = "ARN of the EC2 instance profile for worker nodes."
  value       = aws_iam_instance_profile.eks_nodes.arn
}
