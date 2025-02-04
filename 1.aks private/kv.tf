data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "example" {
  name     = var.rg_name
  location = "${var.rg_location}"
}

resource "azurerm_private_dns_zone" "private_dns_akscluster" {
  name                = "privatelink.westeurope.azmk8s.io"
  resource_group_name = var.rg_name
}  

resource "azurerm_private_dns_zone_virtual_network_link" "dna_akscluster_vnet_link" {
  name                  = "aks-dns-link-vnet"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_akscluster.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}


resource "azurerm_private_dns_zone" "private_dns_aks" {
  depends_on = [ azurerm_resource_group.example ]
  name                = "aks.internal"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dna_aks_vnet_link" {
  depends_on = [ azurerm_private_dns_zone.private_dns_aks ]
  name                  = "aks-dns-link-vnet"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_aks.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_key_vault" "aks_kv" {
  depends_on = [ azurerm_resource_group.example ]
  name                            = var.kv_name
  location                        = azurerm_resource_group.example.location
  resource_group_name             = azurerm_resource_group.example.name
  sku_name                        = "standard" # premium
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization       = true
  public_network_access_enabled   = false
  purge_protection_enabled        = false
  soft_delete_retention_days      = 7
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
    # virtual_network_subnet_ids = var.private_subnet_id
    # ip_rules       = []
  }
}


resource "azurerm_private_dns_zone" "private_dns_kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv_vnet_link" {
  name                  = "kv-dns-link-vnet"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_kv.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_endpoint" "kv_private_endpoint" {
  name                = "kvPrivateEndpoint"
  location            = var.rg_location
  resource_group_name = var.rg_name
  subnet_id           = azurerm_subnet.subnet-private.id

  private_service_connection {
    name                           = "aksAcrDemoConnection"
    private_connection_resource_id = azurerm_key_vault.aks_kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "KeyVaultPrivateDnsZoneGroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_kv.id]
  }
}


/*
resource "azurerm_key_vault_secret" "kvs_username" {
  depends_on   = [azurerm_key_vault.aks_kv,azurerm_role_assignment.cluster_admin]
  name         = "MySecretPassword"
  value        = "P@ssw0rd123!"
  key_vault_id = azurerm_key_vault.aks_kv.id
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "diagnostics_keyvault"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace.id

  log {
    category = "AuditEvent"

    retention_policy {
      enabled = true
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
    }
  }
}


*/
resource "azurerm_role_assignment" "cluster_admin" {
  depends_on = [ azurerm_key_vault.aks_kv ]
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.aks_kv.id
}





