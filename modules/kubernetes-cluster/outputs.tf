output "name" {
  description = "Kubernetes cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "fqdn" {
  description = "Kubernetes cluster FQDN"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "identity" {
  description = "Kubernetes cluster identity"
  value       = azurerm_kubernetes_cluster.main.identity
}

output "kube_config" {
  description = "Kubernetes config"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "kube_config_host" {
  description = "Kubernetes cluster host"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = true
}

output "cluster_id" {
  description = "Kubernetes cluster ID"
  value       = azurerm_kubernetes_cluster.main.id
}

