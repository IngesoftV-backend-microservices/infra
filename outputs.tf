output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = module.kubernetes_cluster.name
}

output "cluster_fqdn" {
  description = "Kubernetes cluster FQDN"
  value       = module.kubernetes_cluster.fqdn
}

output "cluster_identity" {
  description = "Kubernetes cluster identity"
  value       = module.kubernetes_cluster.identity
}

output "kube_config" {
  description = "Kubernetes config to be used with kubectl"
  value       = module.kubernetes_cluster.kube_config
  sensitive   = true
}

output "resource_group_name" {
  description = "Resource group name"
  value       = module.resource_group.name
}

output "vnet_id" {
  description = "Virtual network ID"
  value       = module.networking.vnet_id
}

output "aks_subnet_id" {
  description = "AKS subnet ID"
  value       = module.networking.aks_subnet_id
}

