################################
# Common
################################

variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "domain" {
  type = string
}

variable "load_balancer_virtual_ip" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

################################
# OpenNebula
################################

variable "opennebula_image" {
  type = string
}

variable "opennebula_group" {
  type = string
}

variable "opennebula_virtual_network" {
  type = string
}

variable "cluster_control_plane_capacity" {
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
  nullable = false
  type     = string
  default  = ""
}

variable "cluster_pod_cidr" {
  nullable = false
  type     = string
  default  = "10.244.0.0/16"
}

variable "cluster_service_cidr" {
  nullable = false
  type     = string
  default  = "10.245.0.0/16"
}

variable "extra_cluster_sans" {
  nullable = false
  type     = list(string)
  default  = []
}

################################
# Helm
################################

variable "cluster_addons" {
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
