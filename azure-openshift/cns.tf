
resource "azurerm_availability_set" "cns" {
  name                = "openshift-cns-availability-set"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  managed             = true
}

resource "azurerm_network_security_group" "cns" {
  name                = "openshift-cns-security-group"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
}

resource "azurerm_network_interface" "cns" {
  count                     = "${var.cns_count}"
  name                      = "openshift-cns-nic-${count.index}"
  location                  = "${var.azure_location}"
  resource_group_name       = "${azurerm_resource_group.openshift.name}"
  network_security_group_id = "${azurerm_network_security_group.cns.id}"

  ip_configuration {
    name                                    = "default"
    subnet_id                               = "${azurerm_subnet.cns.id}"
    private_ip_address_allocation           = "dynamic"
  }
}

resource "azurerm_virtual_machine" "cns" {
  count                 = "${var.cns_count}"
  name                  = "openshift-cns-vm-${count.index}"
  location              = "${var.azure_location}"
  resource_group_name   = "${azurerm_resource_group.openshift.name}"
  network_interface_ids = ["${element(azurerm_network_interface.cns.*.id, count.index)}"]
  vm_size               = "${var.cns_vm_size}"
  availability_set_id   = "${azurerm_availability_set.cns.id}"

  storage_image_reference {
    publisher = "${var.os_image_publisher}"
    offer     = "${var.os_image_offer}"
    sku       = "${var.os_image_sku}"
    version   = "${var.os_image_version}"
  }

  storage_os_disk {
    name              = "openshift-cns-vm-os-disk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "openshift-cns-vm-data-disk-${count.index}"
    create_option     = "Empty"
    managed_disk_type = "Standard_LRS"
    lun               = 0
    disk_size_gb      = 100
  }

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  os_profile {
    computer_name  = "cns${count.index}"
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
