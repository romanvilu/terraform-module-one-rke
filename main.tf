################################################################################
# Common
################################################################################

locals {
  cluster_dns_server_ip = cidrhost(var.cluster_service_cidr, 10)
}

resource "random_pet" "this" {
  length = 1
}

resource "random_password" "this" {
  length           = 32
  override_special = "!@#$%&*()-_=+[]<>:?"
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "id_rsa" {
  file_permission = "0600"
  filename        = "${path.root}/.local/${var.environment}/id_rsa"
  content         = tls_private_key.this.private_key_openssh
}

resource "local_sensitive_file" "password" {
  file_permission = "0600"
  filename        = "${path.root}/.local/${var.environment}/passwd"
  content         = "${random_pet.this.id}\n${random_password.this.result}"
}

################################################################################
# OpenNebula
################################################################################

locals {
  tags = merge(
    {
      project     = var.project
      environment = var.environment
      module      = "one-rke"
      terraform   = true
    },
    var.tags
  )
}

data "opennebula_image" "this" {
  name = var.opennebula_image
}

data "opennebula_group" "this" {
  name = var.opennebula_group
}

data "opennebula_virtual_network" "this" {
  name = var.opennebula_virtual_network
}

resource "opennebula_template" "this" {
  name  = "${var.project}-${var.environment}"
  group = data.opennebula_group.this.name
  tags  = local.tags

  context = {
    USERNAME             = random_pet.this.id
    SSH_PUBLIC_KEY       = tls_private_key.this.public_key_openssh
    SET_HOSTNAME         = "$NAME"
    NETWORK              = "YES"
    NETCFG_TYPE          = "netplan"
    NETCFG_RENDERER_TYPE = "networkd"
  }

  graphics {
    type   = "VNC"
    listen = "127.0.0.1"
  }
}

resource "opennebula_virtual_machine" "rke_master" {
  count = var.cluster_control_plane_capacity.size

  name = format(
    "%s-%s-rke-master%s", var.project, var.environment,
    var.cluster_control_plane_capacity.size == 1 ? "" : count.index + 1
  )
  group = data.opennebula_group.this.name
  tags  = local.tags

  template_id = opennebula_template.this.id

  cpu    = var.cluster_control_plane_capacity.cpu
  vcpu   = var.cluster_control_plane_capacity.vcpu
  memory = var.cluster_control_plane_capacity.memory

  nic {
    network_id = data.opennebula_virtual_network.this.id
  }

  disk {
    image_id = data.opennebula_image.this.id
    target   = "vda"
    size     = var.cluster_control_plane_capacity.disk
  }
}

resource "opennebula_virtual_machine" "rke_worker" {
  count = var.cluster_data_plane_capacity.size

  name = format(
    "%s-%s-rke-worker%s", var.project, var.environment,
    var.cluster_data_plane_capacity.size == 1 ? "" : count.index + 1
  )
  group = data.opennebula_group.this.name
  tags  = local.tags

  template_id = opennebula_template.this.id

  cpu    = var.cluster_data_plane_capacity.cpu
  vcpu   = var.cluster_data_plane_capacity.vcpu
  memory = var.cluster_data_plane_capacity.memory

  nic {
    network_id = data.opennebula_virtual_network.this.id
  }

  disk {
    image_id = data.opennebula_image.this.id
    target   = "vda"
    size     = var.cluster_data_plane_capacity.disk
  }

  disk {
    target          = "vdb"
    size            = var.cluster_data_plane_capacity.raw
    driver          = "raw"
    volatile_type   = "fs"
    volatile_format = "raw"
  }
}

resource "opennebula_virtual_machine" "lb" {
  count = var.cluster_load_balancer_capacity.size

  name = format(
    "%s-%s-lb%s", var.project, var.environment,
    var.cluster_load_balancer_capacity.size == 1 ? "" : count.index + 1
  )
  group = data.opennebula_group.this.name
  tags  = local.tags

  template_id = opennebula_template.this.id

  cpu    = var.cluster_load_balancer_capacity.cpu
  vcpu   = var.cluster_load_balancer_capacity.vcpu
  memory = var.cluster_load_balancer_capacity.memory

  nic {
    network_id = data.opennebula_virtual_network.this.id
  }

  disk {
    image_id = data.opennebula_image.this.id
    target   = "vda"
    size     = var.cluster_load_balancer_capacity.disk
  }
}

################################################################################
# Ansible
################################################################################

data "local_file" "hosts_template" {
  filename = "${path.module}/templates/hosts.ini.tftpl"
}

resource "local_file" "hosts" {
  file_permission = "0600"
  filename        = "${path.root}/.local/${var.environment}/hosts.ini"
  content = templatefile(
    data.local_file.hosts_template.filename, {
      LB_NODES         = opennebula_virtual_machine.lb
      RKE_MASTER_NODES = opennebula_virtual_machine.rke_master
      RKE_WORKER_NODES = opennebula_virtual_machine.rke_worker
      LB_VIP           = var.load_balancer_virtual_ip
    }
  )
}

resource "terraform_data" "playbook" {
  provisioner "local-exec" {
    working_dir = "${path.module}/ansible"
    interpreter = ["ansible-playbook"]
    command     = "main.yaml"
    environment = {
      ANSIBLE_FORKS             = 20
      ANSIBLE_TIMEOUT           = 120
      ANSIBLE_SSH_RETRIES       = 5
      ANSIBLE_SSH_ARGS          = "-o ControlMaster=auto -o ControlPersist=60s"
      ANSIBLE_INVENTORY         = abspath(local_file.hosts.filename)
      ANSIBLE_REMOTE_USER       = random_pet.this.id
      ANSIBLE_PRIVATE_KEY_FILE  = abspath(local_sensitive_file.id_rsa.filename)
      ANSIBLE_BECOME            = true
      ANSIBLE_PIPELINING        = true
      ANSIBLE_HOST_KEY_CHECKING = false
    }
  }

  triggers_replace = {
    disks_resized = sum(
      opennebula_virtual_machine.rke_worker[0].disk.*.size
    )
    inventory_changed = sha1(
      local_file.hosts.content
    )
    playbooks_changed = sha1(join("", [
      for f in fileset(path.cwd, "${path.module}/ansible/**") : filesha1(f)
    ]))
  }
}

################################################################################
# RKE
################################################################################

data "local_file" "kubeconfig_template" {
  filename = "${path.module}/templates/kubeconfig.yaml.tftpl"
}

resource "rke_cluster" "this" {
  depends_on = [terraform_data.playbook]

  cluster_name       = var.environment
  kubernetes_version = "v1.27.11-rancher1-1"
  enable_cri_dockerd = true
  addon_job_timeout  = 1000
  ssh_key_path       = local_sensitive_file.id_rsa.filename

  private_registries {
    url        = var.image_registry
    is_default = true
  }

  services {
    kube_api {
      service_cluster_ip_range = var.cluster_service_cidr
    }

    kube_controller {
      cluster_cidr             = var.cluster_pod_cidr
      service_cluster_ip_range = var.cluster_service_cidr
      extra_args = {
        node-monitor-period       = "5s"
        node-monitor-grace-period = "120s"
        cluster-signing-cert-file = "/etc/kubernetes/ssl/kube-ca.pem"
        cluster-signing-key-file  = "/etc/kubernetes/ssl/kube-ca-key.pem"
      }
    }

    kubelet {
      cluster_dns_server = local.cluster_dns_server_ip
      extra_args = {
        container-runtime-endpoint   = "unix:///var/run/crio/crio.sock"
        node-status-update-frequency = "5s"
      }
    }

    kubeproxy {
      extra_args = {
        metrics-bind-address = "0.0.0.0"
      }
    }
  }

  dns { provider = "none" }
  network { plugin = "calico" }
  monitoring { provider = "metrics-server" }

  ingress {
    provider     = "none"
    network_mode = "hostPort"
    http_port    = 80
    https_port   = 443
  }

  authentication {
    strategy = "x509"
    sans = concat(
      [
        "kubernetes.${var.domain}",
        var.load_balancer_virtual_ip,
      ],
      opennebula_virtual_machine.rke_master.*.ip,
      var.extra_cluster_sans
    )
  }

  dynamic "nodes" {
    for_each = opennebula_virtual_machine.rke_master

    content {
      hostname_override = nodes.value.name
      address           = nodes.value.ip
      user              = random_pet.this.id
      role              = ["controlplane", "etcd"]
    }
  }

  dynamic "nodes" {
    for_each = opennebula_virtual_machine.rke_worker

    content {
      hostname_override = nodes.value.name
      address           = nodes.value.ip
      user              = random_pet.this.id
      role              = ["worker"]
    }
  }
}

resource "local_file" "kubeconfig" {
  file_permission = "0600"
  filename        = "${path.root}/.local/${var.environment}/kubeconfig.yaml"
  content = templatefile(
    data.local_file.kubeconfig_template.filename, {
      ENV         = var.environment
      LB_VIP      = var.load_balancer_virtual_ip
      CA_CERT     = rke_cluster.this.ca_crt
      CLIENT_CERT = rke_cluster.this.client_cert
      CLIENT_KEY  = rke_cluster.this.client_key
    }
  )
}

################################################################################
# Helm
################################################################################

resource "helm_release" "coredns" {
  name      = "coredns"
  chart     = "${path.module}/helm/coredns"
  namespace = "kube-system"
  version   = "0.1.0"

  create_namespace  = true
  dependency_update = true
  lint              = true
  atomic            = true

  values = [file("${path.module}/helm/coredns/values.yaml")]

  dynamic "set" {
    for_each = {
      "coredns.image.repository"  = "${var.image_registry}/coredns/coredns"
      "coredns.service.clusterIP" = local.cluster_dns_server_ip
    }
    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "helm_release" "cert_manager" {
  name      = "cert-manager"
  chart     = "${path.module}/helm/cert-manager"
  namespace = "cert-manager"
  version   = "0.1.0"

  create_namespace  = true
  dependency_update = true
  lint              = true
  atomic            = true

  values = [file("${path.module}/helm/cert-manager/values.yaml")]

  dynamic "set" {
    for_each = {
      "global.clusterIssuers.acme.email" = try(
        var.cluster_addons.cert_manager.acme_issuer.email, null
      )
      "global.clusterIssuers.acme.server" = try(
        var.cluster_addons.cert_manager.acme_issuer.server_url, null
      )
      "global.clusterIssuers.acme.hmacKeyId" = try(
        var.cluster_addons.cert_manager.acme_issuer.hmac_key_id, null
      )
    }
    content {
      name  = set.key
      value = set.value
    }
  }

  dynamic "set_sensitive" {
    for_each = {
      "global.clusterIssuers.acme.hmacKeySecret" = try(
        var.cluster_addons.cert_manager.acme_issuer.hmac_key_secret, null
      )
    }
    content {
      name  = set_sensitive.key
      value = set_sensitive.value
    }
  }
}

resource "helm_release" "ingress_nginx" {
  name      = "ingress-nginx"
  chart     = "${path.module}/helm/ingress-nginx"
  namespace = "ingress-nginx"
  version   = "0.1.0"

  create_namespace  = true
  dependency_update = true
  lint              = true
  atomic            = true

  values = [file("${path.module}/helm/ingress-nginx/values.yaml")]

  dynamic "set" {
    for_each = {
      "ingress-nginx.controller.service.externalIPs[0]" = var.load_balancer_virtual_ip
    }
    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "helm_release" "kubernetes_dashboard" {
  depends_on = [
    helm_release.cert_manager,
    helm_release.ingress_nginx
  ]

  name      = "kubernetes-dashboard"
  chart     = "${path.module}/helm/kubernetes-dashboard"
  namespace = "kubernetes-dashboard"
  version   = "0.1.0"

  create_namespace  = true
  dependency_update = true
  lint              = true
  atomic            = true

  values = [file("${path.module}/helm/kubernetes-dashboard/values.yaml")]

  dynamic "set" {
    for_each = {
      "kubernetes-dashboard.ingress.hosts[0]"          = "dashboard.${var.domain}"
      "kubernetes-dashboard.ingress.tls[0].hosts[0]"   = "dashboard.${var.domain}"
      "kubernetes-dashboard.ingress.tls[0].secretName" = "dashboard.${var.domain}-tls"
      "kubernetes-dashboard.image.repository"          = "${var.image_registry}/kubernetesui/dashboard"
    }
    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "helm_release" "longhorn" {
  depends_on = [
    helm_release.cert_manager,
    helm_release.ingress_nginx
  ]

  name      = "longhorn"
  chart     = "${path.module}/helm/longhorn"
  namespace = "longhorn-system"
  version   = "0.1.0"

  create_namespace  = true
  dependency_update = true
  lint              = true
  atomic            = true

  values = [file("${path.module}/helm/longhorn/values.yaml")]

  dynamic "set" {
    for_each = {
      "longhorn.ingress.host"      = "longhorn.${var.domain}"
      "longhorn.ingress.tlsSecret" = "longhorn.${var.domain}-tls"
      "longhorn.defaultSettings.backupTarget" = try(
        var.cluster_addons.longhorn.s3_backup.target, ""
      )
      "longhorn.longhornUI.auth.adminUser" = random_pet.this.id
      "longhorn.longhornManager.s3.endpoint" = try(
        var.cluster_addons.longhorn.s3_backup.endpoint, ""
      )
      "longhorn.longhornManager.s3.accessKeyId" = try(
        var.cluster_addons.longhorn.s3_backup.access_key_id, ""
      )
      "longhorn.privateRegistry.registryUrl" = var.image_registry
    }
    content {
      name  = set.key
      value = set.value
    }
  }

  dynamic "set_sensitive" {
    for_each = {
      "longhorn.longhornUI.auth.adminPassword" = random_password.this.result
      "longhorn.longhornManager.s3.secretAccessKey" = try(
        var.cluster_addons.longhorn.s3_backup.secret_access_key, ""
      )
    }
    content {
      name  = set_sensitive.key
      value = set_sensitive.value
    }
  }
}

resource "helm_release" "grafana_stack" {
  depends_on = [
    helm_release.cert_manager,
    helm_release.ingress_nginx,
    helm_release.longhorn
  ]

  name      = "grafana-stack"
  chart     = "${path.module}/helm/grafana-stack"
  namespace = "grafana-system"
  version   = "0.1.0"

  create_namespace  = true
  dependency_update = true
  lint              = true
  atomic            = true
  timeout           = 600

  values = [file("${path.module}/helm/grafana-stack/values.yaml")]

  dynamic "set" {
    for_each = {
      "alertmanager.basicAuth.user"                                  = random_pet.this.id
      "kube-prometheus-stack.alertmanager.ingress.hosts[0]"          = "alertmanager.${var.domain}"
      "kube-prometheus-stack.alertmanager.ingress.tls[0].hosts[0]"   = "alertmanager.${var.domain}"
      "kube-prometheus-stack.alertmanager.ingress.tls[0].secretName" = "alertmanager.${var.domain}-tls"
      "kube-prometheus-stack.grafana.ingress.hosts[0]"               = "grafana.${var.domain}"
      "kube-prometheus-stack.grafana.ingress.tls[0].hosts[0]"        = "grafana.${var.domain}"
      "kube-prometheus-stack.grafana.ingress.tls[0].secretName"      = "grafana.${var.domain}-tls"
      "kube-prometheus-stack.grafana.adminUser"                      = random_pet.this.id
      "kube-prometheus-stack.grafana.image.registry"                 = var.image_registry
      "loki.sidecar.image.repository"                                = "${var.image_registry}/kiwigrid/k8s-sidecar"
      "loki.minio.consoleIngress.hosts[0]"                           = "loki-minio.${var.domain}"
      "loki.minio.consoleIngress.tls[0].hosts[0]"                    = "loki-minio.${var.domain}"
      "loki.minio.consoleIngress.tls[0].secretName"                  = "loki-minio.${var.domain}-tls"
      "loki.minio.rootUser"                                          = random_pet.this.id
      "loki.global.image.registry"                                   = var.image_registry
      "tempo.tempo.repository"                                       = "${var.image_registry}/grafana/tempo"
      "promtail.global.imageRegistry"                                = var.image_registry
    }
    content {
      name  = set.key
      value = set.value
    }
  }

  dynamic "set_sensitive" {
    for_each = {
      "loki.minio.rootPassword"          = random_password.this.result
      "global.etcd.caCrt"                = rke_cluster.this.ca_crt
      "global.etcd.clientKey" = element([
      "alertmanager.basicAuth.password"             = random_password.this.result
      "kube-prometheus-stack.grafana.adminPassword" = random_password.this.result
        for c in rke_cluster.this.certificates : c.key if startswith(c.id, "kube-etcd")
      ], 0)
      "global.etcd.clientCert" = element([
        for c in rke_cluster.this.certificates : c.certificate if startswith(c.id, "kube-etcd")
      ], 0)
    }
    content {
      name  = set_sensitive.key
      value = set_sensitive.value
    }
  }

  dynamic "set_list" {
    for_each = {
      "global.nginxExporter.endpoints"             = formatlist("%s:9113", opennebula_virtual_machine.lb.*.ip)
      "global.keepalivedExporter.endpoints"        = formatlist("%s:9165", opennebula_virtual_machine.lb.*.ip)
      "kube-prometheus-stack.kubeControllerManager.endpoints" = opennebula_virtual_machine.rke_master.*.ip
      "kube-prometheus-stack.kubeEtcd.endpoints"              = opennebula_virtual_machine.rke_master.*.ip
      "kube-prometheus-stack.kubeScheduler.endpoints"         = opennebula_virtual_machine.rke_master.*.ip
      "kube-prometheus-stack.kubeProxy.endpoints" = concat(
        opennebula_virtual_machine.rke_master.*.ip,
        opennebula_virtual_machine.rke_worker.*.ip
      )
    }
    content {
      name  = set_list.key
      value = set_list.value
    }
  }
}
