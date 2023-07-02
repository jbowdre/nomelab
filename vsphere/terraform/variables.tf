locals {
  vsphere_cluster             = data.vault_kv_secret_v2.vsphere.data["cluster"]
  vsphere_datacenter          = data.vault_kv_secret_v2.vsphere.data["datacenter"]
  vsphere_datastore           = data.vault_kv_secret_v2.vsphere.data["datastore"]
  vsphere_deployment_folder   = data.vault_kv_secret_v2.vsphere.data["deployment_folder"]
  vsphere_endpoint            = data.vault_kv_secret_v2.vsphere.data["endpoint"]
  vsphere_insecure_connection = data.vault_kv_secret_v2.vsphere.data["insecure_connection"]
  vsphere_network             = data.vault_kv_secret_v2.vsphere.data["network"]
  vsphere_password            = data.vault_kv_secret_v2.vsphere.data["password"]
  vsphere_template_folder     = data.vault_kv_secret_v2.vsphere.data["template_folder"]
  vsphere_username            = data.vault_kv_secret_v2.vsphere.data["username"]
  ubuntu_password             = data.vault_kv_secret_v2.ubuntu.data["password"]
  ubuntu_username             = data.vault_kv_secret_v2.ubuntu.data["username"]
  ubuntu_ssh_private_key =
}

variable "nas_allow_ip_cidr" {
  description = "This value will be used in the NAS /etc/exports file to specify which IP CIDR is allowed to access the NFS share. Example: 192.168.0.0/24"
  type        = string
}

variable "nas_disk_size" {
  description = "Size (in GB) of storage volume to create on NAS VM"
  type        = string
}

variable "nodes_blue" {
  description = "A map of host names and MAC addresses for blue nodes"
  type        = map(any)
}

variable "nodes_green" {
  description = "A map of host names and MAC addresses for green nodes"
  type        = map(any)
}

variable "node_k3s" {
  description = "A map of host name and MAC address for k3s node"
  type        = object({ name = string, mac_address = string })
}

variable "node_nas" {
  description = "A map of host name and MAC address for nas node"
  type        = object({ name = string, mac_address = string })
}

variable "ssh_private_key" {
  description = "SSH private key to use for provisioner connection to remote hosts"
  type        = string
}

variable "ssh_username" {
  description = "SSH username to use for provisioner connection to remote hosts"
  type        = string
  default     = "ubuntu"
}

variable "template_blue" {
  description = "Name of template to use for blue nodes"
  type        = string
}

variable "template_green" {
  description = "Name of template to use for green nodes"
  type        = string
}

variable "template_k3s" {
  description = "Name of template to use for k3s nodes"
  type        = string
}

variable "template_nas" {
  description = "Name of template to use for nas node"
  type        = string
}

locals {
  blue_hostnames  = [for k, v in var.nodes_blue : k]
  green_hostnames = [for k, v in var.nodes_green : k]
}
