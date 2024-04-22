################################################################################
# Common
################################################################################

output "admin_username" {
  value = random_pet.this.id
}

output "admin_password" {
  value = nonsensitive(random_password.this.result)
}

output "admin_public_key" {
  value = tls_private_key.this.public_key_openssh
}

output "admin_private_key" {
  value = nonsensitive(tls_private_key.this.private_key_openssh)
}

################################################################################
# OpenNebula
################################################################################

output "cluster_load_balancer_hosts_addresses" {
  value = opennebula_virtual_machine.lb.*.ip
}

output "cluster_control_plane_addresses" {
  value = opennebula_virtual_machine.rke_master.*.ip
}

output "cluster_data_plane_addresses" {
  value = opennebula_virtual_machine.rke_worker.*.ip
}

################################################################################
# Ansible
################################################################################

output "ansible_inventory" {
  value = local_file.hosts.content
}

################################################################################
# RKE
################################################################################

output "cluster_config_yaml" {
  value = rke_cluster.this.rke_cluster_yaml
}

output "cluster_url" {
  value = "https://${var.load_balancer_virtual_ip}:6443"
}

output "cluster_ca_certificate" {
  value = rke_cluster.this.ca_crt
}

output "cluster_client_key" {
  value = rke_cluster.this.client_key
}

output "cluster_client_certificate" {
  value = rke_cluster.this.client_cert
}

output "kubeconfig_path" {
  value = local_file.kubeconfig.filename
}

################################################################################
# Helm
################################################################################

output "addons" {
  value = {
    cert_manager = {
      release_name      = helm_release.cert_manager.name
      release_namespace = helm_release.cert_manager.namespace
    }
    coredns = {
      release_name      = helm_release.coredns.name
      release_namespace = helm_release.coredns.namespace
    }
    grafana_stack = {
      release_name      = helm_release.grafana_stack.name
      release_namespace = helm_release.grafana_stack.namespace
    }
    ingress_nginx = {
      release_name      = helm_release.ingress_nginx.name
      release_namespace = helm_release.ingress_nginx.namespace
    }
    kubernetes_dashboard = {
      release_name      = helm_release.kubernetes_dashboard.name
      release_namespace = helm_release.kubernetes_dashboard.namespace
    }
    longhorn = {
      release_name      = helm_release.longhorn.name
      release_namespace = helm_release.longhorn.namespace
    }
  }
}
