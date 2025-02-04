

resource "azurerm_private_dns_zone" "private_dns_zone8" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns-zone-vnet-link" {
  name                  = "dns-zone-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone8.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = azurerm_resource_group.example.name
}

resource "azurerm_mysql_flexible_server" "mysql" {
  name                   = "mysql-flexserver-hcorp"
  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
  version                = "8.0.21" # 5.7
  delegated_subnet_id    = azurerm_subnet.subnet-2.id
  private_dns_zone_id    = azurerm_private_dns_zone.private_dns_zone8.id
  administrator_login    = "dbadmin"
  administrator_password = "Redhat1449"
  #zone                   = "1"
  sku_name               = "MO_Standard_E2ads_v5" # Standard_D2ads_v5
  backup_retention_days  = 1                  # between 1 and 35, Defaults to 7


  depends_on = [azurerm_private_dns_zone_virtual_network_link.dns-zone-vnet-link]
}

resource "azurerm_private_endpoint" "this" {
  name = "pe-msql"
  location            = var.rg_location
  resource_group_name = var.rg_name
  subnet_id           = azurerm_subnet.subnet-private.id

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone8.id]
  }

  private_service_connection {
    name                           = "mysqlserver-psc"
    private_connection_resource_id = azurerm_mysql_flexible_server.mysql.id
    subresource_names              = ["mysqlserver"]
    is_manual_connection           = false
  }
}


# Manages the MySQL Flexible Server Database
resource "azurerm_mysql_flexible_database" "db" {
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
  name                = "webappdb"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
}

resource "azurerm_mysql_flexible_server_configuration" "require_secure_transport" {
  name                = "require_secure_transport"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  value               = "OFF"
}

########################
# Setup MySQL server logging
########################
resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.log_analytics_workspace != null ? toset(["diagnostics_mysqlserver"]) : []
  #
  name                       = "diagnostics_mysqlserver"
  target_resource_id         = azurerm_mysql_server.this.id
  log_analytics_workspace_id = var.log_analytics_workspace.id

  log {
    category = "MySqlSlowLogs"

    retention_policy {
      enabled = true
    }
  }
  log {
    category = "MySqlAuditLogs"

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
