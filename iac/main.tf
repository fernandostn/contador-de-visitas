module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true

  tags = {
    owner                                       = var.owner
    managed-by                                  = var.managed_by
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

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

module "argocd" {
  source  = "terraform-module/release/helm"
  version = "2.6.0"

  namespace  = kubernetes_namespace.argocd.id
  repository = "https://argoproj.github.io/argo-helm"

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
  source = "terraform-iaac/cert-manager/kubernetes"

  create_namespace = true
  namespace_name   = "cert-manager"

  cluster_issuer_email                   = var.cluster_issuer_email
  cluster_issuer_name                    = var.cluster_issuer_name
  cluster_issuer_private_key_secret_name = var.cluster_issuer_private_key_secret_name
}

resource "kubernetes_namespace" "ingress-nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

module "nginx-controller" {
  source    = "terraform-iaac/nginx-controller/helm"
  namespace = "ingress-nginx"

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

resource "aws_route53_zone" "this" {
  name = var.aws_route53_zone
}

data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
  depends_on = [
    module.eks
  ]
}

resource "aws_route53_record" "this" {
  zone_id = aws_route53_zone.this.zone_id
  name    = var.aws_route53_record
  type    = "CNAME"
  ttl     = "300"
  records = [data.kubernetes_service.ingress_nginx.status.0.load_balancer.0.ingress.0.hostname]
}

# resource "kubernetes_namespace" "monitoring" {
#   metadata {
#     name = "monitoring"
#   }
# }

# resource "helm_release" "kube-prometheus" {
#   name       = "kube-prometheus-stackr"
#   namespace  = "monitoring"
#   # version    = var.kube-version
#   repository = "https://prometheus-community.github.io/helm-charts"
#   chart      = "kube-prometheus-stack"
# }