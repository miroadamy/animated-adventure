
environment    = "dev"
aws_account_id = "992382468947"
aws_region = "eu-west-1"


private_subnet_ids = [
  "subnet-06753af74763de3f9",
  "subnet-03a768d050c07abfa",
  "subnet-0daffb7bb9e308b64"
]
public_subnet_ids = [
  "subnet-0871d2dab922a3c7f",
  "subnet-0d130016bbb19fcc7",
  "subnet-0fcf5d9bd9fd4b14a"
]
vpc_id = "vpc-06bf5c9c1af71aa89"

public_access_cidrs = ["85.216.176.139/32","217.75.91.186/32"]

managed_node_groups = {
  initial = {
    min_size     = 1
    max_size     = 3
    desired_size = 2

    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
  }
}

node_instance_types = ["t3.medium"]
