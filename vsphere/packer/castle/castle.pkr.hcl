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

source "vsphere-iso" "ubuntu-22-castle" {
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
  sources = ["source.vsphere-iso.ubuntu-22-castle"]

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
      "sudo -H -u ${local.ubuntu_username} consul -autocomplete-install",
      "sudo useradd --system --home /etc/consul.d --shell /bin/false consul",
      "sudo mkdir -p -m 755 /opt/consul /etc/consul.d",
      "sudo chown -R consul:consul /opt/consul /etc/consul.d",
      "sudo mv /home/${local.ubuntu_username}/consul.service /usr/lib/systemd/system/consul.service",
    ]
  }

  # install Nomad
  provisioner "shell" {
    inline = [
      "curl --silent -O https://releases.hashicorp.com/nomad/${var.nomad_version}/nomad_${var.nomad_version}_linux_amd64.zip",
      "curl --silent -O https://releases.hashicorp.com/nomad/${var.nomad_version}/nomad_${var.nomad_version}_SHA256SUMS",
      "shasum -c --ignore-missing nomad_${var.nomad_version}_SHA256SUMS",
      "unzip -o nomad_${var.nomad_version}_linux_amd64.zip",
      "sudo chown root:root nomad",
      "sudo mv nomad /usr/bin/",
      "nomad --version",
      "sudo -H -u ${local.ubuntu_username} nomad -autocomplete-install",
      "sudo useradd --system --home /etc/nomad.d --shell /bin/false nomad",
      "sudo mkdir -p -m 755 /opt/nomad /etc/nomad.d",
      "sudo chown -R nomad:nomad /opt/nomad /etc/nomad.d",
      "sudo mv /home/${local.ubuntu_username}/nomad.service /usr/lib/systemd/system/nomad.service",
    ]
  }

  # install Vault
  provisioner "shell" {
    inline = [
      "curl --silent -O https://releases.hashicorp.com/vault/${var.vault_version}/vault_${var.vault_version}_linux_amd64.zip",
      "curl --silent -O https://releases.hashicorp.com/vault/${var.vault_version}/vault_${var.vault_version}_SHA256SUMS",
      "shasum -c --ignore-missing vault_${var.vault_version}_SHA256SUMS",
      "unzip -o vault_${var.vault_version}_linux_amd64.zip",
      "sudo chown root:root vault",
      "sudo mv vault /usr/bin/",
      "vault --version",
      "sudo -H -u ${local.ubuntu_username} vault -autocomplete-install",
      "sudo useradd --system --home /etc/vault.d --shell /bin/false vault",
      "sudo mkdir -p -m 755 /opt/vault/tls /etc/vault.d",
      "sudo chown -R vault:vault /opt/vault /etc/vault.d",
      "sudo mv /home/${local.ubuntu_username}/vault.service /usr/lib/systemd/system/vault.service",
      "sudo touch /var/log/vault_audit.log",
      "sudo chown vault:vault /var/log/vault_audit.log",
      "sudo touch /var/log/vault_audit.pos",
      "sudo chmod 666 /var/log/vault_audit.pos"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/nomad/plugins",
      "curl --silent -OL https://github.com/Roblox/nomad-driver-containerd/releases/download/v${var.containerd_version}/containerd-driver",
      "sudo mv containerd-driver /opt/nomad/plugins/."
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo systemctl daemon-reload",
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "consul_gossip=${local.consul_gossip}",
      "nomad_gossip=${local.nomad_gossip}"
    ]
    inline = [
      "sudo cp /home/${local.ubuntu_username}/consul-agent-ca.pem /etc/vault.d/.",
      "sudo mv /home/${local.ubuntu_username}/consul-agent-ca.pem /etc/consul.d/.",
      "sudo mv /home/${local.ubuntu_username}/consul.hcl /etc/consul.d/.",
      "sudo mv /home/${local.ubuntu_username}/nomad.hcl /etc/nomad.d/.",
      "chmod +x /home/${local.ubuntu_username}/gossip.sh",
      "/home/${local.ubuntu_username}/gossip.sh",
      "sudo chown -R consul:consul /etc/consul.d",
      "sudo chown -R nomad:nomad /etc/nomad.d",
      "sudo chmod 640 /etc/consul.d/* /etc/nomad.d/*"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo \"export CONSUL_HTTP_ADDR=https://127.0.0.1:8501\" | sudo tee -a /root/.bashrc",
      "echo \"export CONSUL_CACERT=/etc/consul.d/consul-agent-ca.pem\" | sudo tee -a /root/.bashrc",
      "echo \"export CONSUL_CLIENT_KEY=/etc/consul.d/dc1-server-consul-key.pem\" | sudo tee -a /root/.bashrc",
      "echo \"export CONSUL_CLIENT_CERT=/etc/consul.d/dc1-server-consul.pem\" | sudo tee -a /root/.bashrc",
      "echo \"export CONSUL_HTTP_ADDR=https://127.0.0.1:8501\" | sudo tee -a /home/${local.ubuntu_username}/.bashrc",
      "echo \"export CONSUL_CACERT=/etc/consul.d/consul-agent-ca.pem\" | sudo tee -a /home/${local.ubuntu_username}/.bashrc",
      "echo \"export CONSUL_CLIENT_KEY=/etc/consul.d/dc1-server-consul-key.pem\" | sudo tee -a /home/${local.ubuntu_username}/.bashrc",
      "echo \"export CONSUL_CLIENT_CERT=/etc/consul.d/dc1-server-consul.pem\" | sudo tee -a /home/${local.ubuntu_username}/.bashrc"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo mv /home/${local.ubuntu_username}/root.crt /usr/local/share/ca-certificates/",
      "sudo update-ca-certificates"
    ]
  }

  provisioner "shell" {
    inline = [
      "DEBIAN_FRONTEND=noninteractive sudo apt-get update; sleep 10",
      "DEBIAN_FRONTEND=noninteractive sudo apt-get upgrade -y; sleep 10",
      "DEBIAN_FRONTEND=noninteractive sudo apt-get autoremove -y"
    ]
  }

  provisioner "shell" {
    inline = [
      "chmod +x /home/${local.ubuntu_username}/VMware-ovftool-4.6.0-21452615-lin.x86_64.bundle",
      "sudo /home/${local.ubuntu_username}/VMware-ovftool-4.6.0-21452615-lin.x86_64.bundle --eulas-agreed --required --console"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/cni/bin/",
      "curl --silent -LO https://github.com/containernetworking/plugins/releases/download/v${var.cni_version}/cni-plugins-linux-amd64-v${var.cni_version}.tgz",
      "sudo tar -xzf cni-plugins-linux-amd64-v${var.cni_version}.tgz -C /opt/cni/bin/"
    ]
  }

  provisioner "shell" {
    inline = [
      "DEBIAN_FRONTEND=noninteractive sudo apt-get install -y apt-transport-https gnupg2",
      "curl --silent -sL 'https://deb.dl.getenvoy.io/public/gpg.8115BA8E629CC074.key' | sudo gpg --dearmor -o /usr/share/keyrings/getenvoy-keyring.gpg",
      "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/getenvoy-keyring.gpg] https://deb.dl.getenvoy.io/public/deb/ubuntu $(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/getenvoy.list",
      "DEBIAN_FRONTEND=noninteractive sudo apt-get update",
      "DEBIAN_FRONTEND=noninteractive sudo apt-get install -y getenvoy-envoy"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo wget -q https://github.com/bcicen/ctop/releases/download/0.7.6/ctop-0.7.6-linux-amd64 -O /usr/local/bin/ctop",
      "sudo chmod +x /usr/local/bin/ctop"
    ]
  }
}