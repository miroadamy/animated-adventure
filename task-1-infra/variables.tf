
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name: [dev, stg, prd]"
  type        = string
  validation {
    condition     = contains(["dev", "prd", "stg"], var.environment)
    error_message = "Variable environment must be one of the following 'dev, stg, prd'."
  }
}

variable "aws_account_id" {
  description = "Account ID"
  type        = string

  validation {
    condition     = length(var.aws_account_id) == 12
    error_message = "aws_account_id must be 12 characters long."
  }
}

variable "aws_region" {
  description = "Cloud Location (region)"
  type        = string
  default = "eu-west-1"
}


variable "vpc_id" {
  description = "ID of the VPC where the cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the cluster"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of private subnet IDs for the cluster"
  type        = list(string)
}


variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "demo"
    Project     = "eks-karpenter-example"
    Terraform   = "true"
  }
}

variable "eks" {
  description = "EKS cluster configuration"
  type = object({
    cluster_name                         = string
    cluster_version                      = string
    cluster_endpoint_public_access       = bool
    cluster_endpoint_public_access_cidrs = list(string)
    managed_node_groups                  = map(any)
    managed_node_group_defaults          = any
  })
  default = {
    cluster_name                         = "eks-karpenter-demo"
    cluster_version                      = "1.32"
    cluster_endpoint_public_access       = true
    cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
    managed_node_groups = {
      system = {
        name           = "eks-system"
        instance_types = ["t4g.small"]
        ami_type       = "AL2_ARM_64"
        min_size       = 1
        max_size       = 3
        desired_size   = 2
        capacity_type  = "ON_DEMAND"
        lifecycle = {
          create_before_destroy = true
        }
      }
    }
    managed_node_group_defaults = {
      ami_type       = "AL2_ARM_64"
      instance_types = ["t4g.small"]
      disk_size      = 20
    }
  }
}

variable "node_instance_types" {
  description = "List of instance types for the EKS managed node groups"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "managed_node_groups" {
  description = "Map of EKS managed node group definitions"
  type        = any
  default = {
    initial = {
      min_size     = 1
      max_size     = 5
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
    }
  }
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = []
}

variable "karpenter_chart_version" {
  type        = string
  description = "Which version of the Karpenter Helm chart to install"
  default     = "1.2.1"
}
