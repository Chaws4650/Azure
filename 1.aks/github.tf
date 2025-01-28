resource "azurerm_user_assigned_identity" "example-1" {
  name                = "terraform-pipeline"
  resource_group_name = var.rg_name
  location            = var.rg_location
  depends_on = [
    azurerm_resource_group.example
  ]

}
data "azurerm_subscription" "current" {}
resource "azurerm_role_assignment" "example-1" {
  principal_id   = azurerm_user_assigned_identity.example-1.principal_id
  role_definition_name = "Contributor"
  scope          = azurerm_resource_group.example.id

depends_on = [
    azurerm_user_assigned_identity.example-1
  ]
}

resource "azurerm_federated_identity_credential" "example-1" {
  name                   = "github-credential"
  parent_id              = azurerm_user_assigned_identity.example-1.id
  resource_group_name    = var.rg_name
  audience               = ["api://AzureADTokenExchange"]
  issuer                 = "https://token.actions.githubusercontent.com"
  subject                = "repo:Chaws4650/1.aks-basic:ref:refs/heads/main"
}