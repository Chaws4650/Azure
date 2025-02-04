resource "azurerm_network_interface" "nic-vm" {
  name                 = "nic-vm"
  depends_on = [ azurerm_resource_group.example ]
  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet-vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = null
  }
}

resource "azurerm_linux_virtual_machine" "vm-linux" {
  name                            = "vm-linux-jumpbox"
  depends_on = [ azurerm_resource_group.example,azurerm_user_assigned_identity.identity-vm ]
  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
  size                            = "Standard_DS2_v2" #"Standard_B1s" 
  disable_password_authentication = false
  admin_username                  = "toor"
  admin_password                  = "AzureCloud123!"
  network_interface_ids           = [azurerm_network_interface.nic-vm.id]
  #priority                        = "Spot"
  #eviction_policy                 = "Deallocate"

  custom_data = filebase64("./install-tools.sh")

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity-vm.id]
  }

  os_disk {
    name                 = "os-disk-vm"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}

resource "azurerm_user_assigned_identity" "identity-vm" {
  name                = "identity-vm"
  depends_on = [ azurerm_resource_group.example ]
  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
}

resource "azurerm_role_assignment" "vm-contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.identity-vm.principal_id
}

data "azurerm_subscription" "current" {}



resource "azurerm_user_assigned_identity" "example-1" {
  name                = "terraform-pipeline"
  resource_group_name = var.rg_name
  location            = var.rg_location
  depends_on = [
    azurerm_resource_group.example
  ]

}

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
