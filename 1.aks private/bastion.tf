resource "azurerm_public_ip" "pip-bastion" {
  depends_on = [ azurerm_resource_group.example ]
  name                = "pip-bastion"
  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  depends_on = [ azurerm_resource_group.example ]
  name                   = "bastion"
  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
  sku                    = "Standard" # "Standard" # "Basic", "Developer"
  copy_paste_enabled     = true
  file_copy_enabled      = false
  shareable_link_enabled = false
  tunneling_enabled      = true
  ip_connect_enabled     = false

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.snet-bastion.id
    public_ip_address_id = azurerm_public_ip.pip-bastion.id
  }
}