
resource "azurerm_network_interface" "revproxy" {
  name                      = "openshift-revproxy-nic"
  location                  = "${var.azure_location}"
  resource_group_name       = "${azurerm_resource_group.openshift.name}"
  network_security_group_id = "${azurerm_network_security_group.revproxy.id}"

  ip_configuration {
    name                          = "default"
    public_ip_address_id          = "${var.public-ip-revproxy}"
    subnet_id                     = "${azurerm_subnet.other.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_network_security_group" "revproxy" {
  name                = "openshift-revproxy-security-group"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
}


resource "azurerm_network_security_rule" "revproxy-http" {
  name                        = "revproxy-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = 80
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.openshift.name}"
  network_security_group_name = "${azurerm_network_security_group.revproxy.name}"
}

resource "azurerm_network_security_rule" "revproxy-https" {
  name                        = "revproxy-https"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = 443
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.openshift.name}"
  network_security_group_name = "${azurerm_network_security_group.revproxy.name}"
}

resource "azurerm_virtual_machine" "revproxy" {
  name                  = "openshift-revproxy-vm"
  location              = "${var.azure_location}"
  resource_group_name   = "${azurerm_resource_group.openshift.name}"
  network_interface_ids = ["${azurerm_network_interface.revproxy.id}"]
  vm_size               = "${var.revproxy_vm_size}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "openshift-revproxy-vm-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  os_profile {
    computer_name  = "revproxy"
    admin_username = "${var.admin_user}"
    admin_password = "${var.admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/${var.admin_user}/.ssh/authorized_keys"
      key_data = "${file("${path.module}/id_rsa_azure_openshift.pub")}"
    }
  }
}
