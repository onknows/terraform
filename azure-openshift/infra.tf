
resource "azurerm_availability_set" "infra" {
  name                = "openshift-infrastructure-availability-set"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  managed             = true
}

resource "azurerm_network_security_group" "infra" {
  name                = "openshift-infrastructure-security-group"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
}

resource "azurerm_network_security_rule" "infra-http" {
  name                        = "infra-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = 80
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.openshift.name}"
  network_security_group_name = "${azurerm_network_security_group.infra.name}"
}

resource "azurerm_network_security_rule" "infra-https" {
  name                        = "infra-https"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 443
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.openshift.name}"
  network_security_group_name = "${azurerm_network_security_group.infra.name}"
}

resource "azurerm_network_interface" "infra" {
  count                     = "${var.infra_count}"
  name                      = "openshift-infrastructure-nic-${count.index}"
  location                  = "${var.azure_location}"
  resource_group_name       = "${azurerm_resource_group.openshift.name}"
  network_security_group_id = "${azurerm_network_security_group.infra.id}"

  ip_configuration {
    name                                    = "default"
    subnet_id                               = "${azurerm_subnet.infra.id}"
    private_ip_address_allocation           = "dynamic"
  }
}

resource "azurerm_virtual_machine" "infra" {
  count                 = "${var.infra_count}"
  name                  = "openshift-infrastructure-vm-${count.index}"
  location              = "${var.azure_location}"
  resource_group_name   = "${azurerm_resource_group.openshift.name}"
  network_interface_ids = ["${element(azurerm_network_interface.infra.*.id, count.index)}"]
  vm_size               = "${var.infra_vm_size}"
  availability_set_id   = "${azurerm_availability_set.infra.id}"

  storage_image_reference {
    publisher = "${var.os_image_publisher}"
    offer     = "${var.os_image_offer}"
    sku       = "${var.os_image_sku}"
    version   = "${var.os_image_version}"
  }

  storage_os_disk {
    name              = "openshift-infrastructure-vm-os-disk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "openshift-infrastructure-vm-data-disk-${count.index}"
    create_option     = "Empty"
    managed_disk_type = "Standard_LRS"
    lun               = 0
    disk_size_gb      = 40
  }

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  os_profile {
    computer_name  = "infra${count.index}"
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
