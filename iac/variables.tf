variable "region" {
  description = "Region used in the project"
  type        = string
}

variable "owner" {
  description = "Owner of the project"
  type        = string
}

variable "managed_by" {
  description = "How the project is managed or created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR used in the project"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC in the project"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS Cluster"
  type        = string
}

variable "cluster_version" {
  description = "Version of the EKS Cluster"
  type        = string
}

variable "instance_type" {
  description = "Instance type used in the EKS Cluster Node Group"
  type        = string
}

variable "cluster_issuer_email" {
  description = "E-mail of the CertManager Cluster Issuer"
  type        = string
}

variable "cluster_issuer_name" {
  description = "Name of the CertManager Cluster Issuer"
  type        = string
}

variable "cluster_issuer_private_key_secret_name" {
  description = "Private Key Secret of the CertManager Cluster Issue"
  type        = string
}

variable "aws_route53_zone" {
  description = "Name of the Route53 Hosted Zone"
  type        = string
}

variable "aws_route53_record" {
  description = "Name of the CNAME to ELB ingress"
  type        = string
}