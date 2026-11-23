# ---------------------------------------------------------------------------
# EKS Cluster Security Group
# Controls traffic between the EKS control plane and worker nodes.
# ---------------------------------------------------------------------------
resource "aws_security_group" "eks_cluster" {
  name        = "${var.name}-cluster-sg"
  description = "Security group for the EKS cluster control plane."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-cluster-sg"
  })
}

# Allow all outbound traffic from the control plane
resource "aws_security_group_rule" "cluster_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.eks_cluster.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic from EKS control plane."
}

# Allow HTTPS inbound — kubectl and AWS API calls use 443
resource "aws_security_group_rule" "cluster_ingress_https" {
  type              = "ingress"
  security_group_id = aws_security_group.eks_cluster.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow HTTPS from within VPC to EKS API server."
}

# ---------------------------------------------------------------------------
# EKS Worker Node Security Group
# Controls traffic on the data plane (EC2 worker nodes / node group).
# ---------------------------------------------------------------------------
resource "aws_security_group" "eks_nodes" {
  name        = "${var.name}-nodes-sg"
  description = "Security group for EKS worker nodes."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name                                        = "${var.name}-nodes-sg"
    "kubernetes.io/cluster/${var.name}-cluster" = "owned"
  })
}

# Allow all outbound from worker nodes
resource "aws_security_group_rule" "nodes_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.eks_nodes.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic from worker nodes."
}

# Allow worker nodes to communicate with each other
resource "aws_security_group_rule" "nodes_ingress_self" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_nodes.id
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  description              = "Allow all traffic between worker nodes."
}

# Allow control plane to communicate with worker nodes (kubelet, metrics)
resource "aws_security_group_rule" "nodes_ingress_cluster" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  description              = "Allow EKS control plane to communicate with worker nodes."
}

# Allow worker nodes to reach the API server
resource "aws_security_group_rule" "nodes_ingress_cluster_https" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  description              = "Allow worker nodes to reach the EKS API server."
}

# Allow worker nodes to respond to control plane
resource "aws_security_group_rule" "cluster_ingress_nodes" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  description              = "Allow worker nodes to call back to EKS API server."
}

# ---------------------------------------------------------------------------
# ALB Security Group
# Controls inbound HTTP/HTTPS traffic to the load balancer.
# ---------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Security group for the Application Load Balancer."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-alb-sg"
  })
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP inbound to ALB."
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS inbound to ALB."
}

resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound from ALB."
}
