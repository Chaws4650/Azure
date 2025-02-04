resource "azurerm_container_registry" "acr" {
    depends_on = [ azurerm_resource_group.example ]
  name                          = "acr4aks4dev465"
  resource_group_name           = azurerm_resource_group.example.name
  location                      = azurerm_resource_group.example.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = true
  zone_redundancy_enabled       = false
  anonymous_pull_enabled        = false
  data_endpoint_enabled         = false
  network_rule_bypass_option    = "AzureServices"
/*
  georeplications {
    location                = "westeurope"
    zone_redundancy_enabled = true
    tags                    = {}
  }

  # georeplications {
  #   location                = "northeurope"
  #   zone_redundancy_enabled = true
  #   tags                    = {}
  # }

  network_rule_set {
      default_action = "Deny"

      ip_rule {
        action   = "Allow"
        ip_range = "49.37.135.151/32"
      }
  }
*/  
}

 resource "azurerm_role_assignment" "acrpull" {
   principal_id                     = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
   role_definition_name             = "AcrPull"
   scope                            = azurerm_container_registry.acr.id
 }

/*
 resource "azurerm_role_assignment" "cluster_admin2" {
  depends_on = [ azurerm_kubernetes_cluster.aks_cluster ]
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}
*/