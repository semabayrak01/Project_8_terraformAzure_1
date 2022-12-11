
#Resource group
resource "azurerm_resource_group" "resource_group_name" {
  name     = var.resource_group_name
  location = var.location
}
# Storage Account
resource "azurerm_storage_account" "storage_account" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.resource_group_name.name
  location                 = azurerm_resource_group.resource_group_name.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    env = "devtf"
  }
}

# Vnet
resource "azurerm_virtual_network" "virtual_network" {
  name                = "${var.vm_name}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resource_group_name.location
  resource_group_name = azurerm_resource_group.resource_group_name.name
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "internal_subnet"
  resource_group_name  = azurerm_resource_group.resource_group_name.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Nic
resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.resource_group_name.location
  resource_group_name = azurerm_resource_group.resource_group_name.name

  ip_configuration {
    name                          = "trconfiguration1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# VM
resource "azurerm_virtual_machine" "vm" {
  name                             = "${var.vm_name}-vm"
  location                         = azurerm_resource_group.resource_group_name.location
  resource_group_name              = azurerm_resource_group.resource_group_name.name
  network_interface_ids            = [azurerm_network_interface.nic.id]
  vm_size                          = "Standard_DS1_v2"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = var.vm_name
    admin_username = var.vm_user_name
    admin_password = var.vm_user_password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }

}