terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.22.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "RG" {
  name     = "Terraform-RG"
  location = "West Europe"
  tags = {
    Environment = "Max-dev"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "matt-vnet"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location
  address_space       = ["10.192.0.0/16"]

  tags = {
    "environment" = "Max-dev"
  }
}

resource "azurerm_subnet" "matt-subnet" {
  name                 = "main-subnet"
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.192.1.0/24"]

}

resource "azurerm_network_security_group" "nsg" {
  name                = "max-nsg"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  tags = {
    environment = "Max-dev"
  }
}

resource "azurerm_network_security_rule" "nsg-dev-rule" {
  name                        = "max-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.RG.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_subnet_network_security_group_association" "nsg-association" {
  subnet_id                 = azurerm_subnet.matt-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "pip" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "Max-dev"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "max-nic"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.matt-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }

  tags = {
    "environment" = "Max-dev"
  }
}

resource "azurerm_linux_virtual_machine" "VM" {
  name                  = "max-vm"
  resource_group_name   = azurerm_resource_group.RG.name
  location              = azurerm_resource_group.RG.location
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.nic.id]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/terraformkey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-script.tpl", {
      hostname = self.public_ip_address,
      user = "adminuser",
      identityfile = "~/.ssh/terraformkey"
    })
    interpreter = var.host_os == "windows" ? ["powershell", "-command"] : ["bash", "-c"]
    # [
    #   "bash", "-c"
    # ]
    # For Linux interpreter:
    # ["bash", "-c"]
  }

  tags = {
    "environment" = "Max-dev"
  }

}

data "azurerm_public_ip" "max-ip-data" {
  name = azurerm_public_ip.pip.name
  resource_group_name = azurerm_resource_group.RG.name
}

output "public_ip_address" {
  value = "${azurerm_linux_virtual_machine.VM.name}: ${data.azurerm_public_ip.max-ip-data.ip_address}"
  
}