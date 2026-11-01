terraform {
  required_providers {
    libvirt = { source = "dmacvicar/libvirt", version = "0.7.6" }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

variable "boot_image" {
  type = string # passed in by lab.sh from the BOM
}

variable "cluster_name" {
  type = string
}

variable "cidr" {
  type = string
}

variable "nodes" {
  type = map(object({ role = string, ip = string, vcpu = number, memory_mb = number }))
}

module "cluster" {
  source       = "git::https://github.com/Ray76/cicd-playground.git//components/terraform/modules/lab-cluster?ref=v0.1.0"
  cluster_name = var.cluster_name
  cidr         = var.cidr
  nodes        = var.nodes
  boot_image   = var.boot_image
}

output "nodes" {
  value = module.cluster.nodes
}
