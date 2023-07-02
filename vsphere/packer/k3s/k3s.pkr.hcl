packer {
  required_version = ">= 1.8.2"
  required_plugins {
    vsphere = {
      version = ">= 1.0.8"
      source = "github.com/hashicorp/vsphere"
    }
    sshkey = {
      version                   = "= 1.0.3"
      source                    = "github.com/ivoronin/sshkey"
    }
  }
}

data "sshkey" "build" {
  type                          = "ed25519"
  name                          = "packer_key"
}

source "vsphere-iso" "ubuntu-22-k3s" {
  insecure_connection         = true
  password                    = local.vsphere_password
  username                    = local.vsphere_username
  vcenter_server              = local.vsphere_endpoint
  cluster                     = local.vsphere_cluster
  datacenter                  = local.vsphere_datacenter
  datastore                   = local.vsphere_datastore
  folder                      = local.vsphere_folder
  boot_command = [
    "<esc><wait>c",
    "linux /casper/vmlinuz --- autoinstall ds=\"nocloud\"",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ]
  boot_order                  = "disk,cdrom"
  boot_wait                   = "5s"
  cd_content                  = local.data_source_content
  cd_label                    = "cidata"
  communicator                = "ssh"
  CPUs                        = "${var.vm_cpu_num}"
  disk_controller_type        = ["pvscsi"]
  firmware                    = "efi-secure"
  guest_os_type               = "ubuntu64Guest"
  iso_checksum                = var.iso_checksum
  iso_url                     = var.iso_url
  RAM                         = "${var.vm_mem_size}"
  remove_cdrom                = true
  shutdown_command            = "sudo -S shutdown -P now"
  ssh_clear_authorized_keys   = true
  ssh_private_key_file        = local.build_private_key_file
  ssh_timeout                 = "1200s"
  ssh_username                = "${local.ubuntu_username}"
  vm_name                     = "${local.vm_name}"
  vm_version                  = "19"
  network_adapters {
    network                   = "${local.vsphere_network}"
    network_card              = "vmxnet3"
  }
  storage {
    disk_size                 = "${var.vm_disk_size}"
    disk_thin_provisioned     = true
  }
}

build {
  sources = ["source.vsphere-iso.ubuntu-22-k3s"]

  provisioner "file" {
    destination = "/home/${local.ubuntu_username}/"
    source      = "files/"
  }

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "SSH_USERNAME=${local.ubuntu_username}"
    ]
    execute_command = "{{.Vars}} sudo -E -S bash '{{.Path}}'"
    scripts = [
      "scripts/docker.sh",
      "scripts/k8s.sh",
      "scripts/k3s.sh",
      "scripts/dashboard.sh",
      "scripts/user.sh"
    ]
  }
}
