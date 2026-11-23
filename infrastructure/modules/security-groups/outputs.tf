output "cluster_sg_id" {
  description = "ID of the EKS cluster control-plane security group."
  value       = aws_security_group.eks_cluster.id
}

output "nodes_sg_id" {
  description = "ID of the EKS worker-node security group."
  value       = aws_security_group.eks_nodes.id
}

output "alb_sg_id" {
  description = "ID of the ALB security group."
  value       = aws_security_group.alb.id
}
