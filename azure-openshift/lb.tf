
resource "azurerm_availability_set" "lb" {
  name                = "openshift-lb-availability-set"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  managed             = true
}

resource "azurerm_network_security_group" "lb" {
  name                = "openshift-lb-security-group"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
}

resource "azurerm_network_interface" "lb" {
  count                     = "${var.lb_count}"
  name                      = "openshift-lb-nic-${count.index}"
  location                  = "${var.azure_location}"
  resource_group_name       = "${azurerm_resource_group.openshift.name}"
  network_security_group_id = "${azurerm_network_security_group.lb.id}"

  ip_configuration {
    name                                    = "default"
    subnet_id                               = "${azurerm_subnet.other.id}"
    private_ip_address_allocation           = "dynamic"
  }
}

resource "azurerm_virtual_machine" "lb" {
  count                 = "${var.lb_count}"
  name                  = "openshift-lb-vm-${count.index}"
  location              = "${var.azure_location}"
  resource_group_name   = "${azurerm_resource_group.openshift.name}"
  network_interface_ids = ["${element(azurerm_network_interface.lb.*.id, count.index)}"]
  vm_size               = "${var.lb_vm_size}"
  availability_set_id   = "${azurerm_availability_set.lb.id}"

  storage_image_reference {
    publisher = "${var.os_image_publisher}"
    offer     = "${var.os_image_offer}"
    sku       = "${var.os_image_sku}"
    version   = "${var.os_image_version}"
  }

  storage_os_disk {
    name              = "openshift-lb-vm-os-disk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  os_profile {
    computer_name  = "lb${count.index}"
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
