terraform {
  required_version = "~> 1.5.7"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.4"
    }
    opennebula = {
      source  = "opennebula/opennebula"
      version = "~> 1.3.0"
    }
    rke = {
      source  = "rancher/rke"
      version = "~> 1.4.4"
    }
  }
}
