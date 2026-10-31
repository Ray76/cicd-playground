output "nodes" {
  value      = { for k, v in var.nodes : k => { ip = v.ip, role = v.role } }
  depends_on = [libvirt_domain.node]
}
