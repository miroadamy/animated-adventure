
# Uncomment and configure the backend block below to use remote state
# Local state is used by default

# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "eks-karpenter/terraform.tfstate"
#     region         = "eu-west-1"
#     dynamodb_table = "terraform-state-lock"
#     encrypt        = true
#   }
# }

