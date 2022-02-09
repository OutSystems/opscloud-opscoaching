#############################################################################
# DATA
#############################################################################
data "azurerm_public_ip" "FEs-PIP" {
  count               = var.coaching-persons * 3
  name                = azurerm_public_ip.pip-coaching[count.index].name
  resource_group_name = azurerm_virtual_machine.vm-coaching[count.index].resource_group_name
}
#############################################################################
# VARIABLES
#############################################################################
variable "client-name" {
  type        = string
  description = "Enter the client name that will be associated to your Resource Group Name"
}
variable "location" {
  type        = string
  description = "Enter the Azure Region for the creation of your Coaching Resource Group. Ex: West Europe / East US / East Asia / UAE North"
}
variable "coaching-persons" {
  type        = number
  description = "Enter how many people in total will be in the coaching"
}
#############################################################################
# PROVIDER
#############################################################################
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.95.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.1.0"
    }
  }
}
provider "azurerm" {
  features {}
}
#############################################################################
# RESOURCES
#############################################################################
locals {
  admin_username = "oscoaching"
  admin_password = "P@$$w0rd1234!"
  script_url     = "https://raw.githubusercontent.com/OutSystems/opscloud-opscoaching/master/powershell/ops_coaching_setup.ps1"
}
resource "azurerm_resource_group" "rg-coaching" {
  name     = "${var.client-name}-Coaching"
  location = var.location
}
resource "random_integer" "vnet-address-space" {
  min = 180
  max = 230
}
resource "azurerm_virtual_network" "vnet-coaching" {
  name                = "VNet-${var.client-name}-Coaching"
  address_space       = ["10.${random_integer.vnet-address-space.result}.0.0/16"] #To be decided based on a random number
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-coaching.name
}
resource "azurerm_subnet" "snet-coaching" {
  name                 = "SNet-${var.client-name}-Coaching"
  resource_group_name  = azurerm_resource_group.rg-coaching.name
  virtual_network_name = azurerm_virtual_network.vnet-coaching.name
  address_prefixes     = ["10.${random_integer.vnet-address-space.result}.1.0/24"] #To be decided based on a random number
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Web"]
}
resource "azurerm_network_security_group" "nsg-coaching" {
  name                = "NSG-${var.client-name}-Coaching"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-coaching.name
}
resource "azurerm_subnet_network_security_group_association" "nsg-subnet-association" {
  subnet_id                 = azurerm_subnet.snet-coaching.id
  network_security_group_id = azurerm_network_security_group.nsg-coaching.id
}
resource "azurerm_network_security_rule" "nsg-coaching-fe-in-http" {
  name                        = "HTTP-in"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg-coaching.name
  network_security_group_name = azurerm_network_security_group.nsg-coaching.name
}
resource "azurerm_network_security_rule" "nsg-coaching-fe-in-https" {
  name                        = "HTTPS-in"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg-coaching.name
  network_security_group_name = azurerm_network_security_group.nsg-coaching.name
}
resource "azurerm_network_security_rule" "nsg-coaching-fe-in-rdp" {
  name                        = "RDP"
  priority                    = 999
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg-coaching.name
  network_security_group_name = azurerm_network_security_group.nsg-coaching.name
}
resource "azurerm_network_security_rule" "nsg-coaching-fe-in-mssql" {
  name                        = "MSSQL"
  priority                    = 998
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg-coaching.name
  network_security_group_name = azurerm_network_security_group.nsg-coaching.name
}
resource "azurerm_public_ip" "pip-coaching" {
  count                   = var.coaching-persons * 3
  name                    = "Pip-Coaching-${count.index}"
  location                = var.location
  resource_group_name     = azurerm_resource_group.rg-coaching.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}
resource "azurerm_public_ip" "pip-sql" {
  name                    = "Pip-Coaching-SQL"
  location                = var.location
  resource_group_name     = azurerm_resource_group.rg-coaching.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}
resource "azurerm_network_interface" "nic-coaching" {
  count               = var.coaching-persons * 3
  name                = "Nic-${count.index}-Coaching"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-coaching.name

  ip_configuration {
    name                          = "Nic-${count.index}-Coaching-ipconfig"
    subnet_id                     = azurerm_subnet.snet-coaching.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-coaching[count.index].id
  }
}
resource "azurerm_network_interface" "nic-sql" {
  name                = "SQL-NIC-Coaching"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-coaching.name

  ip_configuration {
    name                          = "Nic-SQL-Coaching-ipconfig"
    subnet_id                     = azurerm_subnet.snet-coaching.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-sql.id
  }
}
resource "azurerm_virtual_machine" "vm-coaching" {
  count                            = var.coaching-persons * 3
  name                             = "VM-${count.index}-Coaching"
  location                         = var.location
  resource_group_name              = azurerm_resource_group.rg-coaching.name
  network_interface_ids            = [azurerm_network_interface.nic-coaching[count.index].id]
  vm_size                          = "Standard_B2ms" #2vCPUs / 8 GB RAM
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  storage_os_disk {
    name              = "VM-${count.index}-Coaching-OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  storage_data_disk {
    name              = "VM-${count.index}-Coaching-DataDisk"
    caching           = "ReadWrite"
    create_option     = "Empty"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 64
    lun               = 0
  }
  os_profile {
    computer_name  = "VM-${count.index}-Coaching"
    admin_username = local.admin_username
    admin_password = local.admin_password
  }
  os_profile_windows_config {
    enable_automatic_upgrades = false
    provision_vm_agent        = true
  }
}
resource "azurerm_virtual_machine_extension" "vm-coaching-ext" {
  count                = var.coaching-persons * 3
  name                 = "VM-${count.index}-Coaching-Ext"
  virtual_machine_id   = azurerm_virtual_machine.vm-coaching[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  protected_settings   = <<PROTECTED_SETTINGS
    {
      "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File ops_coaching_setup.ps1"
    }
  PROTECTED_SETTINGS

  settings = <<SETTINGS
    {
        "fileUris": [
          "${local.script_url}"
        ]
    }
  SETTINGS
}
resource "azurerm_windows_virtual_machine" "vm-sql-coaching" {
  name                  = "SQL-VM-Coaching"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg-coaching.name
  network_interface_ids = [azurerm_network_interface.nic-sql.id]
  size                  = "Standard_B2ms"
  admin_username        = local.admin_username
  admin_password        = local.admin_password
  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2016SP2-WS2016"
    sku       = "Standard"
    version   = "latest"
  }
  os_disk {
    name                 = "VM-SQL-Coaching-OsDisk"
    caching              = "ReadOnly"
    storage_account_type = "Standard_LRS"
  }
}
resource "azurerm_mssql_virtual_machine" "sql-instance-coaching" {
  virtual_machine_id               = azurerm_windows_virtual_machine.vm-sql-coaching.id
  sql_license_type                 = "PAYG"
  sql_connectivity_port            = 1433
  sql_connectivity_type            = "PRIVATE"
  sql_connectivity_update_password = local.admin_password
  sql_connectivity_update_username = local.admin_username
}
#############################################################################
# OUTPUTS
#############################################################################
output "RG-Name" {
  description = "Coaching Resource Group name"
  value       = "Coaching Resource Group name: ${azurerm_resource_group.rg-coaching.name}"
}
output "FEs-IPs" {
  description = "IPs of all FEs provisoned."
  value       = data.azurerm_public_ip.FEs-PIP.*.ip_address
}
output "SQL-IP" {
  description = "Coaching's SQL Server IP."
  value       = "Private IP: ${azurerm_network_interface.nic-sql.private_ip_address} / Public IP: ${azurerm_windows_virtual_machine.vm-sql-coaching.public_ip_address}"
}
output "vm-creds" {
  description = "VMs Credentials"
  value       = "The credentials to access all the servers (SQL included) are: ${local.admin_username} / ${local.admin_password}"
}