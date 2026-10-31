cluster_name = "dev-1"
cidr         = "10.10.10.0/24"
nodes = {
  cp1 = { role = "controlplane", ip = "10.10.10.10", vcpu = 1, memory_mb = 2096 }
}
