cluster_name                = ""
cluster_version             = "1.32"
cluster_cmk_key             = false
cluster_vpc_id              = ""
cluster_vpc_subnets         = [""]

public_access               = true
admin_cluster_permissions   = true
enable_irsa                 = true

managed_node_group_config   = {
  ami_type                  = "AL2023_x86_64_STANDARD"
  instance_types            = ["t2.medium"]
  min_size                  = 0
  max_size                  = 4
  desired_size              = 2
}

karpenter_namespace         = "kube-system"
karpenter_helm_configs      = {
  name                      = "karpenter-controllers"
  repository                = "oci://public.ecr.aws/karpenter"
  chart_name                = "karpenter"
  chart_version             = "1.2.0"
  sa_creation               = true
}
karpenter_sa_name           = "karpenter-sa"

