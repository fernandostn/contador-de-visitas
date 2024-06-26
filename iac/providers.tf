terraform {
  required_version = ">=1.0.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.48.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.7.1"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.2"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~>2.14.0"
    }
  }

  backend "s3" {
    bucket = "fss-remotestate2"
    key    = "aws/terraform.tfstate.contador-de-visitas"
    region = "us-west-2"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      owner      = var.owner
      managed-by = var.managed_by
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}