terraform {
  required_version = ">=1.0.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.48.0"
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

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true

  tags = {
    owner      = var.owner
    managed-by = var.managed_by
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      min_size     = 2
      max_size     = 3
      desired_size = 2

      instance_types = [var.instance_type]

      tags = {
        owner      = var.owner
        managed-by = var.managed_by
      }
    }
  }

  enable_cluster_creator_admin_permissions = true

  tags = {
    owner      = var.owner
    managed-by = var.managed_by
  }
}

module "argocd" {
  source  = "terraform-module/release/helm"
  version = "2.6.0"

  namespace  = "argocd"
  repository =  "https://argoproj.github.io/argo-helm"

  app = {
    name          = "argocd"
    version       = "3.35.4"
    chart         = "argo-cd"
    force_update  = true
    wait          = true
    recreate_pods = true
    deploy        = 1
  }
  values = [file("./helm-release/argocd-values.yaml")]

  set = [
    {
      name  = "labels.kubernetes\\.io/name"
      value = "argocd"
    },
    {
      name  = "service.labels.kubernetes\\.io/name"
      value = "argocd"
    },
  ]
}

module "cert_manager" {
  source        = "terraform-iaac/cert-manager/kubernetes"

  cluster_issuer_email                   = "fernandostn@gmail.com"
  cluster_issuer_name                    = "cert-manager-global"
  cluster_issuer_private_key_secret_name = "cert-manager-private-key"
}

module "nginx-controller" {
  source  = "terraform-iaac/nginx-controller/helm"

  additional_set = [
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
      value = "nlb"
      type  = "string"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
      value = "true"
      type  = "string"
    }
  ]
}