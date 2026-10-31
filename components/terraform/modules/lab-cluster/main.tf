terraform {
  required_providers {
    libvirt = { source = "dmacvicar/libvirt", version = "0.7.6" }
  }
}

resource "libvirt_network" "net" {
  name      = var.cluster_name
  mode      = "nat"
  addresses = [var.cidr]
  autostart = true
  dhcp {
    enabled = true
  }
  dns {
    enabled = true
  }
}

# Terraform only provides the FIRST boot image. OS upgrades are Ansible's job
# (Step 9), so a new image in a later release must not recreate the VMs.
resource "libvirt_volume" "base" {
  name   = "${var.cluster_name}-talos-base.qcow2"
  pool   = var.pool
  source = var.boot_image
  format = "qcow2"
  lifecycle {
    ignore_changes = [source]
  }
}

resource "libvirt_volume" "disk" {
  for_each       = var.nodes
  name           = "${var.cluster_name}-${each.key}.qcow2"
  pool           = var.pool
  base_volume_id = libvirt_volume.base.id
  size           = var.disk_gb * 1024 * 1024 * 1024
}

resource "libvirt_domain" "node" {
  for_each  = var.nodes
  name      = "${var.cluster_name}-${each.key}"
  vcpu      = each.value.vcpu
  memory    = each.value.memory_mb
  autostart = true

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.disk[each.key].id
  }

  network_interface {
    network_id     = libvirt_network.net.id
    addresses      = [each.value.ip] # becomes a DHCP reservation
    wait_for_lease = false
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}
