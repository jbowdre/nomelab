locals {
  build_private_key_file    = data.sshkey.build.private_key_path
  build_public_key          = data.sshkey.build.public_key
  consul_gossip             = vault("nomelab/data/deployment", "consul_gossip")
  consul_license            = vault("nomelab/data/deployment", "consul_license")
  nomad_gossip              = vault("nomelab/data/deployment", "nomad_gossip")
  nomad_license             = vault("nomelab/data/deployment", "nomad_license")
  ubuntu_nameserver         = vault("nomelab/data/ubuntu", "nameserver")
  ubuntu_password           = vault("nomelab/data/ubuntu", "password")
  ubuntu_password_hash      = vault("nomelab/data/ubuntu", "password_hash")
  ubuntu_public_key         = vault("nomelab/data/ubuntu", "public_key")
  ubuntu_username           = vault("nomelab/data/ubuntu", "username")
  vm_name                   = "k3s"
  vsphere_cluster           = vault("nomelab/data/vsphere", "cluster")
  vsphere_datacenter        = vault("nomelab/data/vsphere", "datacenter")
  vsphere_datastore         = vault("nomelab/data/vsphere", "datastore")
  vsphere_endpoint          = vault("nomelab/data/vsphere", "endpoint")
  vsphere_folder            = vault("nomelab/data/vsphere", "template_folder")
  vsphere_network           = vault("nomelab/data/vsphere", "network")
  vsphere_password          = vault("nomelab/data/vsphere", "password")
  vsphere_username          = vault("nomelab/data/vsphere", "username")
  data_source_content = {
    "/meta-data"            = file("${abspath(path.root)}/meta-data")
    "/user-data"            = templatefile("${abspath(path.root)}/user-data.pkrtpl.hcl", {
      hostname              = local.vm_name
      nameserver            = local.ubuntu_nameserver
      password              = local.ubuntu_password_hash
      ssh_keys              = concat([local.ubuntu_public_key], [local.build_public_key])
      username              = local.ubuntu_username
    })
  }
}

variable "iso_checksum" {
  type    = string
  default = "sha256:5e38b55d57d94ff029719342357325ed3bda38fa80054f9330dc789cd2d43931"
}

variable "iso_url" {
  type    = string
  default = "https://releases.ubuntu.com/jammy/ubuntu-22.04.2-live-server-amd64.iso"
}

variable "vm_cpu_num" {
  type    = string
  default = "2"
}

variable "vm_disk_size" {
  type    = string
  default = "40960"
}

variable "vm_mem_size" {
  type    = string
  default = "8192"
}
