# ---------------------------------------------------------------------------
# EKS Cluster
#
# Floci supports the EKS control-plane API (CreateCluster, DescribeCluster,
# ListClusters). The cluster resource is provisioned and queryable. The
# Kubernetes API server endpoint returned by Floci is a stub — kubectl
# cannot connect to it. Kind (reactivated later) provides the actual runtime.
# ---------------------------------------------------------------------------
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [var.cluster_sg_id]
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
  }

  enabled_cluster_log_types = var.enabled_log_types

  tags = merge(var.tags, {
    Name = var.cluster_name
  })
}
