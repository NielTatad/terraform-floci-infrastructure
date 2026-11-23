resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.retention_days

  tags = merge(var.tags, {
    Name = "/aws/eks/${var.cluster_name}/cluster"
  })
}

resource "aws_cloudwatch_log_group" "eks_application" {
  name              = "/aws/eks/${var.cluster_name}/application"
  retention_in_days = var.retention_days

  tags = merge(var.tags, {
    Name = "/aws/eks/${var.cluster_name}/application"
  })
}
