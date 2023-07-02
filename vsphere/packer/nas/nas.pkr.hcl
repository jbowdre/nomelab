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

source "vsphere-iso" "ubuntu-22-nas" {
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
  sources = ["source.vsphere-iso.ubuntu-22-nas"]

  provisioner "file" {
    destination = "/home/${local.ubuntu_username}/"
    source      = "files/"
  }

  # install Consul
  provisioner "shell" {
    inline = [
      "curl --silent -O https://releases.hashicorp.com/consul/${var.consul_version}/consul_${var.consul_version}_linux_amd64.zip",
      "curl --silent -O https://releases.hashicorp.com/consul/${var.consul_version}/consul_${var.consul_version}_SHA256SUMS",
      "shasum -c --ignore-missing consul_${var.consul_version}_SHA256SUMS",
      "unzip -o consul_${var.consul_version}_linux_amd64.zip",
      "sudo chown root:root consul",
      "sudo mv consul /usr/bin/",
      "consul --version",
      "sudo -H -u ${local.ubuntu_username } consul -autocomplete-install",
      "sudo useradd --system --home /etc/consul.d --shell /bin/false consul",
      "sudo mkdir -p -m 755 /opt/consul /etc/consul.d",
      "sudo chown -R consul:consul /opt/consul /etc/consul.d",
      "sudo mv /home/${local.ubuntu_username}/consul.service /usr/lib/systemd/system/consul.service",
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "sudo apt-get update && sleep 10",
      "sudo apt-get upgrade -y && sleep 10",
      "sudo apt-get autoremove -y && sleep 10"
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "sudo apt-get install -y prometheus-node-exporter",
      "sudo systemctl start prometheus-node-exporter.service",
      "sudo systemctl enable prometheus-node-exporter.service"
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "consul_gossip=${local.consul_gossip}"
    ]
    inline = [
      "sudo mv /home/${local.ubuntu_username}/consul-agent-ca.pem /etc/consul.d/.",
      "sudo mv /home/${local.ubuntu_username}/consul.hcl /etc/consul.d/.",
      "sudo mv /home/${local.ubuntu_username}/nfs.json /etc/consul.d/.",
      "sudo mv /home/${local.ubuntu_username}/node-exporter.json /etc/consul.d/.",
      "chmod +x /home/${local.ubuntu_username}/gossip.sh",
      "/home/${local.ubuntu_username}/gossip.sh",
      "sudo chmod 640 /etc/consul.d/*",
      "sudo chown -R consul:consul /etc/consul.d",
      "sudo hostnamectl set-hostname nas",
      "echo '127.0.1.1       nas.unassigned-domain        nas' | sudo tee -a /etc/hosts",
      "sudo systemctl enable consul && sudo systemctl start consul"
    ]
  }
}
