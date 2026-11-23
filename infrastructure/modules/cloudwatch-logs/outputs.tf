output "cluster_log_group_name" {
  description = "Name of the EKS cluster control-plane log group."
  value       = aws_cloudwatch_log_group.eks_cluster.name
}

output "cluster_log_group_arn" {
  description = "ARN of the EKS cluster control-plane log group."
  value       = aws_cloudwatch_log_group.eks_cluster.arn
}

output "application_log_group_name" {
  description = "Name of the EKS application log group."
  value       = aws_cloudwatch_log_group.eks_application.name
}

output "application_log_group_arn" {
  description = "ARN of the EKS application log group."
  value       = aws_cloudwatch_log_group.eks_application.arn
}
