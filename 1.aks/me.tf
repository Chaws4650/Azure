
# AKS UserAssigned Managed Identity
# resource_id = azurerm_user_assigned_identity.aks_identity.id
# principal_id = azurerm_user_assigned_identity.aks_identity.principal_id

# Role Assignment for Private DNS

resource "azurerm_role_assignment" "aks_identity_dns_role" {
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  role_definition_name = "Private DNS Zone Contributor"
  scope                = azurerm_private_dns_zone.private_dns_aks.id
}
/*
resource "azurerm_role_assignment" "aks_kv_secrets_role" {
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  role_definition_name = "Key Vault Secrets User" # Key Vault Administrator
  scope                = azurerm_key_vault.aks_kv.id
}
*/
resource "azurerm_user_assigned_identity" "this" {
  depends_on = [ azurerm_resource_group.example ]
  name                = "user-identity-aks-4-akv"
  resource_group_name = var.rg_name
  location            = var.rg_location
}
/*
resource "azurerm_role_assignment" "key-vault-secrets-mi" {
  depends_on = [ azurerm_key_vault.aks_kv, azurerm_user_assigned_identity.this ]
  scope                = azurerm_key_vault.aks_kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}
*/
resource "azurerm_federated_identity_credential" "this" {
  depends_on = [ azurerm_kubernetes_cluster.aks_cluster, azurerm_user_assigned_identity.this ]
  name                = "aks-federated-identity-app"
  resource_group_name = var.rg_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks_cluster.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.this.id
  subject             = "system:serviceaccount:app-07:workload-identity-sa"
}
