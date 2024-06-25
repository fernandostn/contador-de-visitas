variable "region" {
  description = "Region used in the project"
  type        = string
  default     = "us-west-2"
}

variable "owner" {
  description = "Owner of the project"
  type        = string
  default     = "Fernando Santana"
}

variable "managed_by" {
  description = "How the project is managed or created"
  type        = string
  default     = "IAC Terraform"
}

variable "vpc_cidr" {
  description = "VPC CIDR used in the project"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name of the VPC in the project"
  type        = string
  default     = "contador-de-visitas_vpc"
}

variable "cluster_name" {
  description = "Name of the EKS Cluster"
  type        = string
  default     = "contador-de-visitas"
}

variable "cluster_version" {
  description = "Version of the EKS Cluster"
  type        = string
  default     = "1.30"
}

variable "instance_type" {
  description = "Instance type used in the EKS Cluster Node Group"
  type        = string
  default     = "t3.small"
}
