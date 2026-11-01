variable "cluster_name" {
  type = string
}

variable "cidr" {
  type = string
}

variable "boot_image" {
  type        = string
  description = "Local path of the Talos qcow2 used for the first boot only"
}

variable "nodes" {
  type = map(object({
    role      = string # controlplane | worker
    ip        = string
    vcpu      = number
    memory_mb = number
  }))
}

variable "pool" {
  type    = string
  default = "default"
}

variable "disk_gb" {
  type    = number
  default = 10
}
