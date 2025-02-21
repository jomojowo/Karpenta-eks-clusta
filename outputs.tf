# Output the cluster endpoint, certificate authority, oidc_provider arn.
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "oidc_provider_arn_output" {
  value = module.eks.oidc_provider_arn
}
