locals {
  tags = merge(var.tags, { modulo = "azure-recovery" })
}

resource "azurerm_resource_group" "this" {
  name     = "${var.name}-recuperacion"
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.name}-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  address_space       = [var.vnet_cidr]
  tags                = local.tags
}

resource "azurerm_subnet" "app" {
  name                 = "app"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.app_cidr]
}

resource "azurerm_subnet" "data" {
  name                 = "datos"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.data_cidr]
}

# --- NSG ---
resource "azurerm_network_security_group" "app" {
  name                = "${var.name}-nsg-app"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags

  security_rule {
    name                       = "https-desde-cloudflare"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = var.cloudflare_cidrs
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "denegar-resto"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "data" {
  name                = "${var.name}-nsg-datos"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags

  security_rule {
    name                       = "postgres-desde-app"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = var.app_cidr
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "denegar-resto"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_subnet_network_security_group_association" "data" {
  subnet_id                 = azurerm_subnet.data.id
  network_security_group_id = azurerm_network_security_group.data.id
}

# --- VM de aplicacion (IP publica solo para el origen detras de Cloudflare) ---
resource "azurerm_public_ip" "app" {
  name                = "${var.name}-app-ip"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "app" {
  name                = "${var.name}-app-nic"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app.id
  }
}

resource "azurerm_network_interface" "db" {
  name                = "${var.name}-db-nic"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.data.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "app" {
  name                            = "${var.name}-app"
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  size                            = var.app_vm_size
  admin_username                  = "azureops"
  network_interface_ids           = [azurerm_network_interface.app.id]
  disable_password_authentication = true
  custom_data                     = base64encode(file("${path.module}/app-cloud-init.sh"))
  tags                            = local.tags

  admin_ssh_key {
    username   = "azureops"
    public_key = var.admin_ssh_public_key
  }
  identity {
    type = "SystemAssigned"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "db" {
  name                            = "${var.name}-db"
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  size                            = var.db_vm_size
  admin_username                  = "azureops"
  network_interface_ids           = [azurerm_network_interface.db.id]
  disable_password_authentication = true
  custom_data                     = base64encode(templatefile("${path.module}/db-cloud-init.sh.tftpl", { pg_major = var.pg_major }))
  tags                            = local.tags

  admin_ssh_key {
    username   = "azureops"
    public_key = var.admin_ssh_public_key
  }
  identity {
    type = "SystemAssigned"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

# Las VM leen la copia con su identidad administrada (sin claves ni secretos).
resource "azurerm_role_assignment" "backup_reader" {
  for_each = var.backup_container_id == "" ? {} : {
    app = azurerm_linux_virtual_machine.app.identity[0].principal_id
    db  = azurerm_linux_virtual_machine.db.identity[0].principal_id
  }
  scope                = var.backup_container_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = each.value
}
