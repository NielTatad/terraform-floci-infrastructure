locals {
  common_tags = {
    environment = var.environment
    project     = var.project
    managed_by  = "terraform"
  }

  # Naming prefix — all resources are prefixed with this
  name = "floci-eks"
}

# ---------------------------------------------------------------------------
# Phase 1: Networking
# ---------------------------------------------------------------------------

module "vpc" {
  source = "../../modules/vpc"

  name                 = local.name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = true
  tags                 = local.common_tags
}

module "security_groups" {
  source = "../../modules/security-groups"

  name     = local.name
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr
  tags     = local.common_tags
}

# ---------------------------------------------------------------------------
# Phase 2: IAM
# ---------------------------------------------------------------------------

module "iam_eks" {
  source = "../../modules/iam-eks"

  name = local.name
  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Phase 3: CloudWatch Logs (must exist before EKS cluster)
# ---------------------------------------------------------------------------

module "cloudwatch_logs" {
  source = "../../modules/cloudwatch-logs"

  cluster_name   = var.cluster_name
  retention_days = var.log_retention_days
  tags           = local.common_tags
}

# ---------------------------------------------------------------------------
# Phase 4: EKS Cluster
# ---------------------------------------------------------------------------

module "eks_cluster" {
  source = "../../modules/eks-cluster"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  cluster_role_arn   = module.iam_eks.cluster_role_arn
  cluster_sg_id      = module.security_groups.cluster_sg_id

  # Cluster spans both public and private subnets
  subnet_ids = concat(
    module.vpc.public_subnet_ids,
    module.vpc.private_subnet_ids
  )

  endpoint_private_access = true
  endpoint_public_access  = true

  enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = local.common_tags

  depends_on = [
    module.iam_eks,
    module.cloudwatch_logs,
  ]
}

# ---------------------------------------------------------------------------
# Phase 5: EKS Managed Node Group
# ---------------------------------------------------------------------------

module "eks_nodegroup" {
  source = "../../modules/eks-nodegroup"

  cluster_name   = module.eks_cluster.cluster_name
  nodegroup_name = var.nodegroup_name
  node_role_arn  = module.iam_eks.node_role_arn

  # Worker nodes run in private subnets only
  subnet_ids = module.vpc.private_subnet_ids

  desired_size   = var.node_desired_size
  min_size       = var.node_min_size
  max_size       = var.node_max_size
  instance_types = var.node_instance_types
  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  tags = local.common_tags

  depends_on = [module.eks_cluster]
}

# ---------------------------------------------------------------------------
# Phase 6: ECR
# ---------------------------------------------------------------------------

module "ecr" {
  source = "../../modules/ecr"

  repository_name         = var.ecr_repository_name
  image_tag_mutability    = "MUTABLE"
  scan_on_push            = true
  enable_lifecycle_policy = true
  max_image_count         = 10
  tags                    = local.common_tags
}

# ---------------------------------------------------------------------------
# Phase 7: Application Load Balancer
# ---------------------------------------------------------------------------

module "alb" {
  source = "../../modules/alb"

  name              = "${local.name}-alb"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
  target_port       = 80
  health_check_path = "/healthz"
  tags              = local.common_tags
}
