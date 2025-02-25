variable "cluster_name" {
  type = string
  description = "Name of EKS cluster that we be created."
}

variable "cluster_version" {
  type = string
  description = "EKS cluster version that will be created."
}

variable "cluster_vpc_id" {
  type = string
  description = "AWS VPC ID to use for networking of eks cluster."
}

variable "cluster_vpc_subnets" {
  type = list(string)
  description = "List of private subnet ids to use for eks cluster and it's nodegroups, nodepools."
}

variable "public_access" {
  type = bool
  description = "Toggle to determine if public access should be enabled."
}

variable "cluster_cmk_key" {
  type = bool
  description = "Enable creation of cmk kms key for cluster encryption."
}

variable "admin_cluster_permissions" {
  type = bool
  description = "Toggle to determine if cluster creator admin permissions should be granted."
}

variable "enable_irsa" {
  type = bool
  description = "Toggle to determine if OIDC provider for EKS cluster be created, these will be use for IRSA."
}

variable "managed_node_group_config" {
  type = object({
    ami_type        = string
    instance_types  = list(string)
    min_size        = number
    max_size        = number
    desired_size    = number
  })
}

variable "karpenter_helm_configs" {
  type = object({
    name            = string
    repository      = string
    chart_name      = string
    chart_version   = string
    sa_creation     = bool
  })
}

variable "karpenter_sa_name" {
  type = string
  description = "Name of ServiceAccount for Karpenter"
}

variable "karpenter_namespace" {
  type = string
  description = "Name of namespace to deploy karpenter into."
}
