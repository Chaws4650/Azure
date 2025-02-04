resource "azurerm_virtual_network" "vnet" {
  name                = "aks-vnet"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "aks-private"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.2.0.0/24"]
}

resource "azurerm_subnet" "snet-bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.2.1.0/24"]
}

resource "azurerm_subnet" "snet-vm" {
  name                 = "snet-vm"
  resource_group_name  = azurerm_virtual_network.vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.2.2.0/24"]
}

resource "azurerm_subnet" "subnet-private" {
  name                 = "aks-private-services"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.2.3.0/24"]
}


resource "azurerm_network_security_group" "public_security_group" {
  name                = "public-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "AllowInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*" # "Internet"
    destination_address_prefix = "*"
  }
}

# Public Network Security Group Association
resource "azurerm_subnet_network_security_group_association" "public_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.public_security_group.id
}

resource "azurerm_network_security_group" "vm-nsg" {
  name                = "${azurerm_virtual_network.vnet.name}-${azurerm_subnet.snet-vm.name}-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}
resource "azurerm_subnet_network_security_group_association" "subnet" {
  subnet_id                 = azurerm_subnet.snet-vm.id
  network_security_group_id = azurerm_network_security_group.vm-nsg.id
}