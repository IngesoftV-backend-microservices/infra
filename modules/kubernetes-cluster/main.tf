# Kubernetes Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.cluster_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.dns_prefix}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name            = var.default_node_pool.name
    node_count      = var.default_node_pool.node_count
    vm_size         = var.default_node_pool.vm_size
    os_disk_size_gb = var.default_node_pool.os_disk_size_gb
    type            = var.default_node_pool.type
    max_pods        = var.default_node_pool.max_pods
    vnet_subnet_id  = var.vnet_subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = var.rbac_enabled

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.environment}"
  })

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      kubernetes_version,
      default_node_pool[0].node_count
    ]
  }
}

# Additional node pools
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  node_count            = each.value.node_count
  vm_size               = each.value.vm_size
  os_disk_size_gb       = each.value.os_disk_size_gb
  max_pods              = each.value.max_pods

  tags = var.tags
}

