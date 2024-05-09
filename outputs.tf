################################################################################
# Common
################################################################################

output "admin_username" {
  description = "Generated administrator username"
  value       = random_pet.this.id
}

output "admin_password" {
  description = "Generated administrator password"
  value       = nonsensitive(random_password.this.result)
}

output "admin_public_key" {
  description = "Generated administrator OpenSSH public key"
  value       = tls_private_key.this.public_key_openssh
}

output "admin_private_key" {
  description = "Generated administrator OpenSSH private key"
  value       = nonsensitive(tls_private_key.this.private_key_openssh)
}

################################################################################
# OpenNebula
################################################################################

output "cluster_load_balancer_hosts_addresses" {
  description = "IP addresses of Kubernetes cluster external load balancing nodes"
  value       = opennebula_virtual_machine.lb.*.ip
}

output "cluster_control_plane_addresses" {
  description = "IP addresses of Kubernetes cluster control plane nodes"
  value       = opennebula_virtual_machine.rke_master.*.ip
}

output "cluster_data_plane_addresses" {
  description = "IP addresses of Kubernetes cluster worker nodes"
  value       = opennebula_virtual_machine.rke_worker.*.ip
}

################################################################################
# Ansible
################################################################################

output "ansible_inventory" {
  description = "Contents of generated Ansible inventory"
  value       = local_file.hosts.content
}

################################################################################
# RKE
################################################################################

output "cluster_config_yaml" {
  description = "Kubernetes cluster configuration file"
  value       = rke_cluster.this.rke_cluster_yaml
}

output "cluster_url" {
  description = "Endpoint of Kubernetes cluster API server"
  value       = "https://${var.load_balancer_virtual_ip}:6443"
}

output "cluster_ca_certificate" {
  description = "CA certificate of Kubernetes cluster API server"
  value       = rke_cluster.this.ca_crt
}

output "cluster_client_key" {
  description = "Client key to access Kubernetes cluster API server"
  value       = rke_cluster.this.client_key
}

output "cluster_client_certificate" {
  description = "Client certificate to access Kubernetes cluster API server"
  value       = rke_cluster.this.client_cert
}

output "kubeconfig_path" {
  description = "Path of kubeconfig file to access Kubernetes cluster API server"
  value       = local_file.kubeconfig.filename
}

################################################################################
# Helm
################################################################################

output "addons" {
  description = "Kubernetes cluster addons attributes"

  value = {
    coredns = {
      name      = helm_release.coredns.name
      namespace = helm_release.coredns.namespace
    }
    cert_manager = {
      name      = helm_release.cert_manager.name
      namespace = helm_release.cert_manager.namespace
    }
    ingress_nginx = {
      name      = helm_release.ingress_nginx.name
      namespace = helm_release.ingress_nginx.namespace
    }
    kubernetes_dashboard = {
      name      = helm_release.kubernetes_dashboard.name
      namespace = helm_release.kubernetes_dashboard.namespace
    }
    longhorn = {
      name      = helm_release.longhorn.name
      namespace = helm_release.longhorn.namespace
    }
    grafana_stack = {
      name      = helm_release.grafana_stack.name
      namespace = helm_release.grafana_stack.namespace
    }
  }
}
