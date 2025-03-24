
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
  default = "eu-central-2"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the cluster"
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
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
