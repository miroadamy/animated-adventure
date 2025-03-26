# Test / support resources

This module builds resources that are not part of the assignment, but I need them to test / validate the solution

Minimalistic code / throw-away => don't fret about best practices and hardcoded stuff.

Using local state.

You have been warned :-D

M.A.


Used resources:

GH main · yyosefi/codiumai-challenge
https://github.com/yyosefi/codiumai-challenge/

### Output example

```sh
Outputs:

private_subnet_ids = [
  "subnet-0f2a43cf784460cc7",
  "subnet-0d238cf1796869779",
  "subnet-027b9de3a2c1c73b1",
]
public_subnet_ids = [
  "subnet-02782f4085586aa3c",
  "subnet-0090a3aba634f2036",
  "subnet-07cb105c573f23a99",
]
vpc_id = "vpc-01d0a20129334a7d5"
```

### Created resources
eu-west-1

```json
{
    "Vpcs": [
        {
            "OwnerId": "992382468947",
            "InstanceTenancy": "default",
            "CidrBlockAssociationSet": [
                {
                    "AssociationId": "vpc-cidr-assoc-0e9b6c1edfb35f26d",
                    "CidrBlock": "172.31.0.0/16",
                    "CidrBlockState": {
                        "State": "associated"
                    }
                }
            ],
            "IsDefault": true,
            "VpcId": "vpc-0630912b1dda3d649",
            "State": "available",
            "CidrBlock": "172.31.0.0/16",
            "DhcpOptionsId": "dopt-04a91f066e9c1b51e"
        },
        {
            "OwnerId": "992382468947",
            "InstanceTenancy": "default",
            "CidrBlockAssociationSet": [
                {
                    "AssociationId": "vpc-cidr-assoc-0772436bada2c185f",
                    "CidrBlock": "10.0.0.0/16",
                    "CidrBlockState": {
                        "State": "associated"
                    }
                }
            ],
            "IsDefault": false,
            "Tags": [
                {
                    "Key": "Example",
                    "Value": "ex-test-support"
                },
                {
                    "Key": "GithubOrg",
                    "Value": "terraform-aws-modules"
                },
                {
                    "Key": "GithubRepo",
                    "Value": "terraform-aws-eks"
                },
                {
                    "Key": "Name",
                    "Value": "ex-test-support"
                }
            ],
            "VpcId": "vpc-01d0a20129334a7d5",
            "State": "available",
            "CidrBlock": "10.0.0.0/16",
            "DhcpOptionsId": "dopt-04a91f066e9c1b51e"
        }
    ]
}

```