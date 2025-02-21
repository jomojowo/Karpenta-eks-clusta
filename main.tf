## Create the EKS cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id = var.cluster_vpc_id
  subnet_ids = var.cluster_vpc_subnets

  cluster_endpoint_public_access = var.public_access
  enable_cluster_creator_admin_permissions = var.admin_cluster_permissions

  # Enable IRSA
  enable_irsa     = var.enable_irsa
  create_kms_key  = var.cluster_cmk_key
  cluster_encryption_config = {}


  authentication_mode = "API_AND_CONFIG_MAP"

  eks_managed_node_groups = {
    karpenter = {
      ami_type       = var.managed_node_group_config.ami_type
      instance_types = var.managed_node_group_config.instance_types

      min_size     = var.managed_node_group_config.min_size
      max_size     = var.managed_node_group_config.max_size
      desired_size = var.managed_node_group_config.desired_size

      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }
    }
  }

  tags = {
    Environment = "Test"
    Terraform   = "true"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

}


resource "helm_release" "karpenter" {
  namespace           = var.karpenter_namespace
  name                = var.karpenter_helm_configs.name
  repository          = var.karpenter_helm_configs.repository
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = var.karpenter_helm_configs.chart_name
  version             = var.karpenter_helm_configs.chart_version
  wait                = false
  create_namespace    = true

  values = [
    <<-EOT
    nodeSelector:
      karpenter.sh/controller: 'true'
    dnsPolicy: Default
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
    webhook:
      enabled: false
    EOT
  ]

  set {
    name  = "serviceAccount.create"
    value = var.karpenter_helm_configs.sa_creation
  }

  set {
    name  = "serviceAccount.name"
    value = var.karpenter_sa_name
  }

  depends_on = [module.eks]
}


