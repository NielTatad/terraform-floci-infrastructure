# ---------------------------------------------------------------------------
# EKS Managed Node Group
#
# Floci supports CreateNodegroup / DescribeNodegroup at the API level.
# The node group is registered as a resource and queryable via AWS CLI.
# Actual EC2 worker nodes are not launched — Kind provides the real runtime.
# ---------------------------------------------------------------------------
resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.nodegroup_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  instance_types = var.instance_types
  ami_type       = var.ami_type
  capacity_type  = var.capacity_type
  disk_size      = var.disk_size

  update_config {
    max_unavailable = 1
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.nodegroup_name}"
  })
}
