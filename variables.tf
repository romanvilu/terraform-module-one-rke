################################
# Common
################################

variable "project" {
  description = "Name of the project in which current module is used. Will be used to prefix OpenNebula resources"
  type        = string
}

variable "environment" {
  description = "Shortname of the environment for which module is used, e.g. `dev` or `live`"
  type        = string
}

variable "domain" {
  description = "Main domain, e.g. `example.com`, under which cluster services will be published as subdomains"
  type        = string
}

variable "load_balancer_virtual_ip" {
  description = "Virtual IP address for cluster external load balancer"
  type        = string
}

variable "extra_tags" {
  description = "Additional tags for OpenNebula resources"
  type        = map(string)
  default     = {}
}

################################
# OpenNebula
################################

variable "opennebula_image" {
  description = "Name of existing Ubuntu 22.04 Server or Minimal image for virtual machines in OpenNebula"
  type        = string
}

variable "opennebula_group" {
  description = "Name of existing group which will own created resources in OpenNebula"
  type        = string
}

variable "opennebula_virtual_network" {
  description = "Name of existing virtual network in OpenNebula to attach virtual machines to"
  type        = string
}

variable "cluster_control_plane_capacity" {
  description = "Per-node (except for host count variable `size`) capacity of Kubernetes cluster control plane hosts"

  nullable = false

  type = object({
    size      = optional(number, 3)
    cpu       = optional(number, 2)
    vcpu      = optional(number, 4)
    memory_mb = optional(number, 8192)
    disk_mb   = optional(number, 102400)
  })

  default = {
    size      = 3
    cpu       = 2
    vcpu      = 4
    memory_mb = 8192
    disk_mb   = 102400
  }
}

variable "cluster_data_plane_capacity" {
  description = "Per-node (except for host count variable `size`) capacity of Kubernetes cluster worker hosts"

  nullable = false

  type = object({
    size      = optional(number, 3)
    cpu       = optional(number, 4)
    vcpu      = optional(number, 8)
    memory_mb = optional(number, 16384)
    disk_mb   = optional(number, 204800)
    datadisk_mb    = optional(number, 512000)
  })

  default = {
    size        = 3
    cpu         = 4
    vcpu        = 8
    memory_mb   = 16384
    disk_mb     = 204800
    datadisk_mb = 512000
  }
}

variable "cluster_load_balancer_capacity" {
  description = "Per-node (except for host count variable `size`) capacity of Kubernetes external load balancing hosts"

  nullable = false

  type = object({
    size      = optional(number, 2)
    cpu       = optional(number, 1)
    vcpu      = optional(number, 2)
    memory_mb = optional(number, 4096)
    disk_mb   = optional(number, 20480)
  })

  default = {
    size      = 2
    cpu       = 1
    vcpu      = 2
    memory_mb = 4096
    disk_mb   = 20480
  }
}

################################
# RKE
################################

variable "image_registry" {
  description = "Private image registry to use instead of Docker Hub (may be useful due to Docker Hub rate limit)"

  nullable = false
  type     = string
  default  = ""
}

variable "cluster_pod_cidr" {
  description = "CIDR block used to assign IP addresses to Pods in Kubernetes cluster"

  nullable = false
  type     = string
  default  = "10.244.0.0/16"
}

variable "cluster_service_cidr" {
  description = "CIDR block used to assign IP addresses to Services in Kubernetes cluster"

  nullable = false
  type     = string
  default  = "10.245.0.0/16"
}

variable "extra_cluster_sans" {
  description = "Additional domain names/IP addresses to include in Kubernetes API server certificate"

  nullable = false
  type     = list(string)
  default  = []
}

################################
# Helm
################################

variable "cluster_addons" {
  description = "Additional configurations for Kubernetes cluster addons"

  nullable = false

  type = object({
    cert_manager = optional(object({
      acme_issuer = optional(object({
        email           = string
        server_url      = string
        hmac_key_id     = string
        hmac_key_secret = string
      }))
    }))

    longhorn = optional(object({
      s3_backup = optional(object({
        endpoint          = string
        target            = string
        access_key_id     = string
        secret_access_key = string
      }))
    }))
  })

  default = {}
}
