# one-rke
**one-rke** is a Terraform module aiming to provide a fully functional
[Rancher Kubernetes Engine](https://github.com/rancher/rke) (RKE) cluster with its underlying infrastructure and
required infrastructure services and addons in OpenNebula private cloud.

<!-- TOC -->
* [one-rke](#one-rke)
  * [Features](#features)
  * [Documentation](#documentation)
    * [External](#external)
  * [Repository Tree](#repository-tree)
  * [Usage](#usage)
  * [Requirements](#requirements)
  * [Resources](#resources)
  * [Inputs](#inputs)
  * [Outputs](#outputs)
<!-- TOC -->

## Features
- Virtual infrastructure creation in [OpenNebula](https://opennebula.io/)
- Host configuration management using [Ansible](https://github.com/ansible/ansible)
- Kubernetes cluster installation using [RKE](https://github.com/rancher/rke)
- Cluster infrastructure services deployment using [Helm](https://github.com/helm/helm)

## Documentation
### External
- [Terraform documentation](https://developer.hashicorp.com/terraform/docs)
- [Kubernetes documentation](https://kubernetes.io/docs/home/)
- [OpenNebula documentation](https://docs.opennebula.io/6.6/)
- [RKE documentation](https://rke.docs.rancher.com/)
- [Ansible documentation](https://docs.ansible.com/)
- [Helm documentation](https://helm.sh/docs/)

## Repository Tree
Tree below is generated using command `tree --dirsfirst --charset ASCII`.

```text
.
|-- ansible
|   |-- roles
|   |   |-- crio
|   |   |   `-- tasks
|   |   |       `-- main.yaml
|   |   |-- docker
|   |   |   |-- files
|   |   |   |   `-- daemon.json
|   |   |   |-- handlers
|   |   |   |   `-- main.yaml
|   |   |   `-- tasks
|   |   |       `-- main.yaml
|   |   |-- init
|   |   |   `-- tasks
|   |   |       `-- main.yaml
|   |   |-- keepalived
|   |   |   |-- files
|   |   |   |   `-- prometheus-keepalived-exporter.service
|   |   |   |-- tasks
|   |   |   |   |-- keepalived_exporter.yaml
|   |   |   |   |-- keepalived.yaml
|   |   |   |   `-- main.yaml
|   |   |   `-- templates
|   |   |       `-- keepalived.conf.j2
|   |   |-- lvm
|   |   |   `-- tasks
|   |   |       `-- main.yaml
|   |   |-- nginx
|   |   |   |-- tasks
|   |   |   |   |-- main.yaml
|   |   |   |   |-- nginx_exporter.yaml
|   |   |   |   `-- nginx.yaml
|   |   |   `-- templates
|   |   |       |-- nginx.conf.j2
|   |   |       `-- prometheus-nginx-exporter.j2
|   |   |-- post
|   |   |   `-- tasks
|   |   |       `-- main.yaml
|   |   `-- swap
|   |       `-- tasks
|   |           `-- main.yaml
|   `-- main.yaml
|-- helm
|   |-- cert-manager
|   |   |-- templates
|   |   |   `-- clusterissuer.yaml
|   |   |-- Chart.lock
|   |   |-- Chart.yaml
|   |   `-- values.yaml
|   |-- coredns
|   |   |-- Chart.lock
|   |   |-- Chart.yaml
|   |   `-- values.yaml
|   |-- grafana-stack
|   |   |-- files
|   |   |   `-- scrape-configs.yaml
|   |   |-- templates
|   |   |   |-- opentelemetry-operator
|   |   |   |   |-- java-intrumentation.yaml
|   |   |   |   `-- java-opentelemetrycollector.yaml
|   |   |   |-- prometheus
|   |   |   |   |-- etcd-secret.yaml
|   |   |   |   `-- scrape-configs-secret.yaml
|   |   |   `-- _helpers.tpl
|   |   |-- Chart.lock
|   |   |-- Chart.yaml
|   |   `-- values.yaml
|   |-- ingress-nginx
|   |   |-- Chart.lock
|   |   |-- Chart.yaml
|   |   `-- values.yaml
|   |-- kubernetes-dashboard
|   |   |-- Chart.lock
|   |   |-- Chart.yaml
|   |   `-- values.yaml
|   `-- longhorn
|       |-- templates
|       |   |-- backup-target-secret.yaml
|       |   `-- basic-auth-secret.yaml
|       |-- Chart.lock
|       |-- Chart.yaml
|       `-- values.yaml
|-- templates
|   |-- hosts.ini.tftpl
|   `-- kubeconfig.yaml.tftpl
|-- main.tf
|-- outputs.tf
|-- README.md
|-- variables.tf
`-- versions.tf
```

| Name                                                                  | Description                                        |
|-----------------------------------------------------------------------|----------------------------------------------------|
| ansible/                                                              | Ansible playbook directory                         |
| helm/                                                                 | Helm charts directory                              |
| templates/                                                            | Terraform template files                           |
| templates/hosts.ini.tftpl                                             | Ansible inventory template file                    |
| templates/kubeconfig.yaml.tftpl                                       | kubeconfig template file                           |
| main.tf                                                               | Main set of module configurations                  |
| outputs.tf                                                            | Output definitions                                 |
| README.md                                                             | Module documentation                               |
| variables.tf                                                          | Variable definitions                               |
| versions.tf                                                           | Version definitions                                |
 
## Usage
To use module, use and adjust example code block brought below.

```terraform
provider "opennebula" {
  endpoint = "https://opennebula.example.com:2634/RPC2"
  username = "example"
  password = "example"
}

provider "helm" {
  kubernetes {
    host                   = module.one_rke.cluster_url
    cluster_ca_certificate = module.one_rke.cluster_ca_certificate
    client_key             = module.one_rke.cluster_client_key
    client_certificate     = module.one_rke.cluster_client_certificate
  }
}

module "one_rke" {
  source = "github.com/romanvilu/terraform-module-one-rke"

  project     = "example"
  environment = "ex"
  domain      = "example.com"
  
  tags = {
    example = true
  }
  
  loadbalancer_virtual_ip = "1.2.3.4"
  
  opennebula_image           = "ubuntu-22.04-minimal"
  opennebula_group           = "example"
  opennebula_virtual_network = "example"
  
  cluster_addons = {
    cert_manager = {
      acme_issuer = {
        email           = "example@example.com"
        server_url      = "https://acme.sectigo.com/v2/OV"
        hmac_key_id     = "example"
        hmac_key_secret = "example"
      }
    }

    longhorn = {
      s3_backup = {
        endpoint          = "https://s3.example.com/"
        target            = "s3://example-bucket@example-region/"
        access_key_id     = "example"
        secret_access_key = "example"
      }
    }
  }
}
```

## Requirements
Required versions of Terraform and used providers (from `versions.tf` file).

| Name                  | Version   |
|-----------------------|-----------|
| terraform             | ~> 1.5.7  |
| hashicorp/helm        | ~> 2.12.1 |
| hashicorp/local       | ~> 2.4.0  | 
| hashicorp/random      | ~> 3.5.1  | 
| hashicorp/tls         | ~> 4.0.4  |
| opennebula/opennebula | ~> 1.3.0  |
| rancher/rke           | ~> 1.4.4  |

## Resources
List of resources that the module may (!) create (from `main.tf` file).
See more about Terraform [resources](https://developer.hashicorp.com/terraform/language/resources/syntax).

| Name                                  | Type        | Description                                                                                     |
|---------------------------------------|-------------|-------------------------------------------------------------------------------------------------|
| random_pet.this                       | resource    | Administrator's random username                                                                 |
| random_password.this                  | resource    | Administrator's random password                                                                 |
| tls_private_key.this                  | resource    | Administrator's SSH key pair                                                                    |
| local_sensitive_file.id_rsa           | resource    | Contains SSH private key                                                                        |
| local_sensitive_file.password         | resource    | Contains administrator's username and password                                                  |
| opennebula_template.this              | resource    | Virtual machine template                                                                        |
| opennebula_virtual_machine.rke_master | resource    | RKE master host                                                                                 |
| opennebula_virtual_machine.rke_worker | resource    | RKE worker host                                                                                 |
| opennebula_virtual_machine.lb         | resource    | Load balancing host                                                                             |
| local_file.hosts                      | resource    | Ansible inventory file                                                                          |                       
| terraform_data.playbook               | resource    | Ansible playbook execution                                                                      | 
| rke_cluster.this                      | resource    | RKE cluster                                                                                     |
| local_file.kubeconfig                 | resource    | Kubeconfig file                                                                                 |
| helm_release.cert_manager             | resource    | cert-manager Helm release                                                                       |
| helm_release.coredns                  | resource    | CoreDNS Helm release                                                                            |
| helm_release.ingress_nginx            | resource    | NGINX Ingress Controller Helm release                                                           |
| helm_release.longhorn                 | resource    | Longhorn Helm release                                                                           |
| helm_release.grafana_stack            | resource    | Grafana Stack (Prometheus, Grafana, Loki, Tempo, OpenTelemetry Operator, Promtail) Helm release |
| helm_release.kubernetes_dashboard     | resource    | Kubernetes Dashboard Helm release                                                               |
| opennebula_image.this                 | data source | Ubuntu 22.04 LTS minimal image                                                                  |
| opennebula_group.this                 | data source | Owner group for OpenNebula resources                                                            |
| opennebula_virtual_network.this       | data source | Virtual network for virtual machines                                                            |
| local_file.hosts_template             | data source | Ansible inventor  template                                                                      |
| local_file.kubeconfig_template        | data source | Kubeconfig template                                                                             |

## Inputs
List of values that the module may use (i.e. both optional and required ones).
See more about Terraform [input variables](https://developer.hashicorp.com/terraform/language/values/variables).

| Name                                                    | Description                                                                                  | Type           | Default         | Required |
|---------------------------------------------------------|----------------------------------------------------------------------------------------------|----------------|-----------------|----------|
| project                                                 | Project name to append to names of resources                                                 | `string`       |                 | yes      |
| environment                                             | Environment name to append to names of resources                                             | `string`       |                 | yes      |
| domain                                                  | DNS domain to use for domain names of resources                                              | `string`       |                 | yes      |
| load_balancer_virtual_ip                                | Virtual IP to use for cluster access                                                         | `string`       |                 | yes      |
| tags                                                    | Additional tags for OpenNebula resources                                                     | `map(string)`  | `{}`            | no       |
| opennebula_image                                        | Name of Ubuntu 22.04 LTS minimal image                                                       | `string`       |                 | yes      |
| opennebula_group                                        | Name of group to which assign created OpenNebula resources                                   | `string`       |                 | yes      |
| cluster_control_plane_capacity                          | Configuration of RKE master hosts resources                                                  | `object(any)`  |                 | no       |
| cluster_control_plane_capacity.size                     | Amount of hosts                                                                              | `number`       | `3`             | no       |
| cluster_control_plane_capacity.cpu                      | Amount of CPU per host                                                                       | `number`       | `2`             | no       |
| cluster_control_plane_capacity.vcpu                     | Amount of vCPU per host                                                                      | `number`       | `4`             | no       |
| cluster_control_plane_capacity.memory                   | Amount of memory per hosts in MB                                                             | `number`       | `8192`          | no       |
| cluster_control_plane_capacity.disk                     | Disk size per host in MB                                                                     | `number`       | `40960`         | no       |
| cluster_data_plane_capacity                             | Configuration of RKE worker hosts resources                                                  | `object(any)`  |                 | no       |
| cluster_data_plane_capacity.size                        | Amount of hosts                                                                              | `number`       | `3`             | no       |
| cluster_data_plane_capacity.cpu                         | Amount of CPU per host                                                                       | `number`       | `4`             | no       |
| cluster_data_plane_capacity.vcpu                        | Amount of vCPU per host                                                                      | `number`       | `8`             | no       |
| cluster_data_plane_capacity.memory                      | Amount of memory per hosts in MB                                                             | `number`       | `16392`         | no       |
| cluster_data_plane_capacity.disk                        | Disk size per host in MB                                                                     | `number`       | `40960`         | no       |
| cluster_data_plane_capacity.raw                         | Data disk size per host in MB                                                                | `number`       | `51200`         | no       |
| cluster_load_balancer_capacity                          | Configuration of load balancer hosts resources                                               | `object(any)`  |                 | no       |
| cluster_load_balancer_capacity.size                     | Amount of hosts                                                                              | `number`       | `2`             | no       |
| cluster_load_balancer_capacity.cpu                      | Amount of CPU per host                                                                       | `number`       | `1`             | no       |
| cluster_load_balancer_capacity.vcpu                     | Amount of vCPU per host                                                                      | `number`       | `2`             | no       |
| cluster_load_balancer_capacity.memory                   | Amount of memory per hosts in MB                                                             | `number`       | `4096`          | no       |
| cluster_load_balancer_capacity.disk                     | Disk size per host in MB                                                                     | `number`       | `20480`         | no       |
| image_registry                                          | URL of private image registry (without `http(s)://`)                                         | `string`       | `""`            | no       |
| cluster_pod_cidr                                        | CIDR to be used for assigning pod IP addresses (must not overlap with existing networks)     | `string`       | `10.244.0.0/16` | no       |
| cluster_service_cidr                                    | CIDR to be used for assigning service IP addresses (must not overlap with existing networks) | `string`       | `10.245.0.0/16` | no       |
| extra_cluster_sans                                      | Extra SANs for cluster's API server                                                          | `list(string)` | `[]`            | no       |
| cluster_addons                                          | Configuration of RKE cluster addons                                                          | `object(any)`  |                 | no       |
| cluster_addons.cert_manager                             | Configuration of cert-manager addon                                                          | `object(any)`  |                 | no       |
| cluster_addons.cert_manager.acme_issuer                 | Configuration of ACME cluster issuer                                                         | `object(any)`  |                 | no       |
| cluster_addons.cert_manager.acme_issuer.email           | Email to be used for notifications                                                           | `string`       |                 | yes      |
| cluster_addons.cert_manager.acme_issuer.server_url      | ACME server URL                                                                              | `string`       |                 | yes      |
| cluster_addons.cert_manager.acme_issuer.hmac_key_id     | HMAC account key ID                                                                          | `string`       |                 | yes      |
| cluster_addons.cert_manager.acme_issuer.hmac_key_secret | HMAC account key secret                                                                      | `string`       |                 | yes      |
| cluster_addons.longhorn                                 | Configuration of Longhorn addon                                                              | `object(any)`  |                 | no       |
| cluster_addons.longhorn.s3_backup                       | Configuration of backup to S3                                                                | `object(any)`  |                 | no       |
| cluster_addons.longhorn.s3_backup.endpoint              | S3 server endpoint                                                                           | `string`       |                 | yes      |
| cluster_addons.longhorn.s3_backup.target                | S3 bucket endpoint                                                                           | `string`       |                 | yes      |
| cluster_addons.longhorn.s3_backup.access_key_id         | S3 access key ID                                                                             | `string`       |                 | yes      |
| cluster_addons.longhorn.s3_backup.secret_access_key     | S3 secret access key                                                                         | `string`       |                 | yes      |

## Outputs
List of values that the module can return after or during its execution (from `outputs.tf` file).
See more about Terraform [output values](https://developer.hashicorp.com/terraform/language/values/outputs).

| Name                                          | Description                                           |
|-----------------------------------------------|-------------------------------------------------------|
| admin_username                                | Administrator's randomly generated username           |
| admin_password                                | Administrator's randomly generated password           |
| admin_public_key                              | Administrator's SSH public key                        |
| admin_private_key                             | Administrator's SSH private key                       |
| cluster_control_plane_addresses               | IP addresses of cluster control plane hosts           |
| cluster_data_plane_addresses                  | IP addresses of cluster data plane hosts              |
| cluster_load_balancer_hosts_addresses         | IP addresses of cluster load balancer hosts           |
| ansible_inventory                             | Ansible inventory                                     |
| cluster_config_yaml                           | RKE cluster configuration                             |
| kubeconfig_path                               | kubeconfig absolute file path                         |
| addons                                        | Information of Kubernetes addons                      |
| addons.coredns                                | CoreDNS addon                                         |
| addons.coredns.release_name                   | CoreDNS addon Helm release name                       |
| addons.coredns.release_namespace              | CoreDNS addon Helm release namespace                  |
| addons.cert_manager                           | cert-manager addon                                    |
| addons.cert_manager.release_name              | cert-manager addon Helm release name                  |
| addons.cert_manager.release_namespace         | cert-manager addon Helm release namespace             |
| addons.ingress_nginx                          | NGINX Ingress Controller addon                        |
| addons.ingress_nginx.release_name             | NGINX Ingress Controller addon Helm release name      |
| addons.ingress_nginx.release_namespace        | NGINX Ingress Controller addon Helm release namespace |
| addons.longhorn                               | Longhorn addon                                        |
| addons.longhorn.release_name                  | Longhorn addon Helm release name                      |
| addons.longhorn.release_namespace             | Longhorn addon Helm release namespace                 |
| addons.kubernetes_dashboard                   | Kubernetes Dashboard addon                            |
| addons.kubernetes_dashboard.release_name      | Kubernetes Dashboard addon Helm release name          |
| addons.kubernetes_dashboard.release_namespace | Kubernetes Dashboard addon Helm release namespace     |
| addons.grafana_stack                          | Grafana Stack addon                                   |
| addons.grafana_stack.release_name             | Grafana Stack addon Helm release name                 |
| addons.grafana_stack.release_namespace        | Grafana Stack addon Helm release namespace            |
