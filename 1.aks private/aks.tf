resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                                = "aks-cluster"
  location                            = var.rg_location
  resource_group_name                 = var.rg_name
  sku_tier                            = "Free" # Standard Premium
  support_plan                        = "KubernetesOfficial" # AKSLongTermSupport
  private_cluster_enabled             = true # true
  private_cluster_public_fqdn_enabled = false
  dns_prefix_private_cluster          = "aks-cluster"
  private_dns_zone_id                 = azurerm_private_dns_zone.private_dns_akscluster.id
  #private_dns_zone_id                 = azurerm_private_dns_zone.private_dns_aks.id
  role_based_access_control_enabled   = true # Kubernetes RBAC
  oidc_issuer_enabled                 = true
  local_account_disabled              = false # When true, enable role_based_access_control_enabled & azure_active_directory_role_based_access_control
  #dns_prefix                        = "azure"
  # Enable Azure AD/Microsoft Entra Workload Identity
  workload_identity_enabled = true # When true, oidc_issuer_enabled must be true
  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"
  node_resource_group       = "rg-aks-node"

  identity {
    type         = "UserAssigned" # SystemAssigned
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet_identity.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet_identity.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet_identity.id
  }

  network_profile {
    # network_plugin     = "azure" # kubenet
    # network_policy     = "azure" # "calico"/"cilium"
    # network_data_plane = "azure"
    network_plugin    = "azure"
    network_plugin_mode = "overlay"
    load_balancer_sku = "standard"     # standard
    outbound_type     = "loadBalancer" # "userDefinedRouting"

    # allows for more control over egress traffic in the future
    # load_balancer_profile {
    #   outbound_ip_address_ids = [azurerm_public_ip.aks_outbound_ip.id]
    # }
  }
  storage_profile {
    disk_driver_enabled = false
    file_driver_enabled = false
    snapshot_controller_enabled = false
  } 
/*
   api_server_access_profile {
     authorized_ip_ranges = ["49.37.135.151/32"] # API server access from Authorized IP ranges
   }
*/  
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }
  default_node_pool {
    name                         = "system"
    type                         = "VirtualMachineScaleSets"
    vm_size                      = "Standard_D2_v2"
    os_disk_size_gb              = 30
    vnet_subnet_id               = azurerm_subnet.subnet.id
    zones                        = [2]
    node_count                   = 2
    auto_scaling_enabled         = true # Enable Cluster Autoscaler
    min_count                    = 2
    max_count                    = 3
    temporary_name_for_rotation  = "tempsystem" # Temporary node pool name used to cycle the default node pool for VM resizing
    only_critical_addons_enabled = false

    node_labels = {
      "worker-name" = "system"
    }
  }
  # Enable Azure Key Vault provider for Secrets Store CSI Driver
  key_vault_secrets_provider {
    secret_rotation_enabled = true
    secret_rotation_interval = "24h"
  }

  lifecycle {
    ignore_changes = [
      auto_scaler_profile,
      default_node_pool
    ]
  }
    web_app_routing {
     dns_zone_ids = [azurerm_private_dns_zone.private_dns_aks.id]
   }


/*   
   oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.workspace.id
    msi_auth_for_monitoring_enabled = true
  }

  monitor_metrics {
    annotations_allowed = null
    labels_allowed      = null
  }
*/
  depends_on = [
    azurerm_private_dns_zone.private_dns_aks,
    azurerm_subnet.subnet,
    azurerm_resource_group.example,
    azurerm_user_assigned_identity.aks_identity,
    azurerm_user_assigned_identity.kubelet_identity
  ]
    }

resource "azurerm_role_assignment" "aks_identity_rg_role" {
  depends_on = [ azurerm_resource_group.example ]
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  role_definition_name = "Contributor"
  scope                = azurerm_resource_group.example.id
}

resource "azurerm_user_assigned_identity" "aks_identity" {
  depends_on = [ azurerm_resource_group.example ]
  name                = "aks-identity"
  location            = var.rg_location
  resource_group_name = var.rg_name
}

resource "azurerm_user_assigned_identity" "kubelet_identity" {
  depends_on = [ azurerm_resource_group.example ]
  name                = "kubelet-identity"
  location            = var.rg_location
  resource_group_name = var.rg_name
}

# Role Assignment for Kubelet Identity
resource "azurerm_role_assignment" "kubelet_role_assignment" {
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  scope                = azurerm_user_assigned_identity.kubelet_identity.id
  role_definition_name = "Managed Identity Operator"
}

/*
resource "terraform_data" "aks-get-credentials" {
  depends_on = [ azurerm_kubernetes_cluster.aks_cluster ]
  triggers_replace = [
    azurerm_kubernetes_cluster.aks_cluster.id
  ]

  provisioner "local-exec" {
    command = "az aks get-credentials -n ${azurerm_kubernetes_cluster.aks_cluster.name} -g ${azurerm_kubernetes_cluster.aks_cluster.resource_group_name} --overwrite-existing"
  }
}

resource "terraform_data" "app-routing-add-dns-zone" {
  depends_on = [ azurerm_kubernetes_cluster.aks_cluster ]
  triggers_replace = [
    azurerm_kubernetes_cluster.aks_cluster.id,
    azurerm_private_dns_zone.private_dns_aks.id
  ]

  provisioner "local-exec" {
    command = "az aks approuting zone add -n ${azurerm_kubernetes_cluster.aks_cluster.name} -g ${azurerm_kubernetes_cluster.aks_cluster.resource_group_name} --ids=${azurerm_private_dns_zone.private_dns_aks.id} --attach-zones"
  }
}
*/
data "azurerm_user_assigned_identity" "webapp_routing" {
  depends_on = [ azurerm_kubernetes_cluster.aks_cluster ]
  name                = split("/", azurerm_kubernetes_cluster.aks_cluster.web_app_routing.0.web_app_routing_identity.0.user_assigned_identity_id)[8]
  resource_group_name = azurerm_kubernetes_cluster.aks_cluster.node_resource_group
}

resource "azurerm_role_assignment" "key-vault-secrets-user" {
  depends_on = [ azurerm_key_vault.aks_kv ]
  scope                = azurerm_key_vault.aks_kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_user_assigned_identity.webapp_routing.principal_id
}

resource "azurerm_role_assignment" "dns-zone-contributor" {
  depends_on = [ azurerm_private_dns_zone.private_dns_aks ]
  scope                = azurerm_private_dns_zone.private_dns_aks.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = data.azurerm_user_assigned_identity.webapp_routing.principal_id
}

resource "azurerm_role_assignment" "cluster_admin1" {
  depends_on = [ azurerm_kubernetes_cluster.aks_cluster ]
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.aks_cluster.id
}

