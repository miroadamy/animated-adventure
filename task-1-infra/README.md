# Task 1 - EKS with Karpenter - Terraform

Requirements: see [Requirements](./Requirements.md)

This Terraform project deploys an Amazon EKS cluster with Karpenter for node autoscaling, supporting both x86 and ARM/Graviton instances

It allows creation of 3 environments - dev, stg, prd, according the variable values in `./env/dev.tfvars` etc

## Quick Start


```bash
export AWS_PROFILE=your-profile

# Alternatively:
# export AWS_ACCESS_KEY_ID=your-key-id
# export AWS_SECRET_ACCESS_KEY=your-secret-key

# Modify the VPC and subnets in each environment
# env/dev.tfvars

# init, plan and apply
terraform init
terraform plan -var-file=./env/dev.tfvars
terraform apply -var-file=./env/dev.tfvars

# connect to EKS cluster
./scripts/connect-to-cluster.sh --cluster-name YOUR-CLUSTER-NAME
```

Here is an example of the output

```
➜  task-1-infra git:(main) ✗ ./scripts/connect-to-cluster.sh --cluster-name eks-karpenter-demo
Connecting to EKS cluster: eks-karpenter-demo in region: eu-west-1

Updating kubeconfig...
Updated context arn:aws:eks:eu-west-1:992382468947:cluster/eks-karpenter-demo in /Users/miroadamy/.kube/config

Verifying connection to the cluster...
NAME                                        STATUS   ROLES    AGE   VERSION
ip-10-0-18-193.eu-west-1.compute.internal   Ready    <none>   17m   v1.32.1-eks-5d632ec
ip-10-0-3-153.eu-west-1.compute.internal    Ready    <none>   82m   v1.32.1-eks-5d632ec
ip-10-0-38-100.eu-west-1.compute.internal   Ready    <none>   82m   v1.32.1-eks-5d632ec

Checking Karpenter installation...
NAME                         READY   STATUS    RESTARTS   AGE
karpenter-66d8f64cdb-9lqpf   1/1     Running   0          23m

Karpenter NodePools:
NAME          NODECLASS   NODES   READY   AGE
default-arm   default     0       True    23m
default-x86   default     1       True    23m

Karpenter EC2NodeClasses:
NAME      READY   AGE
default   True    23m
```

## Verification that the ARM/X86 deployment works:

```
# deploy sample workloads that will trigger Karpenter provisioning
kubectl apply -f examples/architecture/nginx-x86.yaml    # For x86/AMD64
kubectl apply -f examples/architecture/nginx-arm64.yaml  # For ARM64/Graviton
```

Here is an example of the output:

```
➜  task-1-infra git:(main) ✗ kubectl apply -f examples/architecture/nginx-arm64.yaml
deployment.apps/nginx-arm64 created
➜  task-1-infra git:(main) ✗ kubectl apply -f examples/architecture/nginx-x86.yaml
deployment.apps/nginx-x86 created

➜  task-1-infra git:(main) ✗ kubectl get nodepools                                  
NAME          NODECLASS   NODES   READY   AGE
default-arm   default     0       True    6m9s
default-x86   default     1       True    6m9s


➜  task-1-infra git:(main) ✗ k get pods -A
NAMESPACE     NAME                           READY   STATUS    RESTARTS   AGE
default       nginx-arm64-84fd95c454-x56qm   1/1     Running   0          2m9s
default       nginx-arm64-84fd95c454-xjxbg   1/1     Running   0          2m9s
default       nginx-x86-7d9c8bbbd-7xv8d      1/1     Running   0          112s
default       nginx-x86-7d9c8bbbd-q9bpg      1/1     Running   0          112s
karpenter     karpenter-66d8f64cdb-9lqpf     1/1     Running   0          7m14s
kube-system   aws-node-9d7mc                 2/2     Running   0          65m
kube-system   aws-node-9wb2t                 2/2     Running   0          80s
kube-system   aws-node-ml7jl                 2/2     Running   0          65m
kube-system   coredns-5b7cdbc9-272n9         1/1     Running   0          69m
kube-system   coredns-5b7cdbc9-ms2qw         1/1     Running   0          69m
kube-system   kube-proxy-5lfn7               1/1     Running   0          65m
kube-system   kube-proxy-pm9v2               1/1     Running   0          80s
kube-system   kube-proxy-z2sth               1/1     Running   0          65m

k get nodes -o wide
NAME                                        STATUS   ROLES    AGE    VERSION               INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION                    CONTAINER-RUNTIME
ip-10-0-18-193.eu-west-1.compute.internal   Ready    <none>   112s   v1.32.1-eks-5d632ec   10.0.18.193   <none>        Amazon Linux 2023.6.20250303   6.1.129-138.220.amzn2023.x86_64   containerd://1.7.25
ip-10-0-3-153.eu-west-1.compute.internal    Ready    <none>   66m    v1.32.1-eks-5d632ec   10.0.3.153    <none>        Amazon Linux 2                 5.10.234-225.910.amzn2.aarch64    containerd://1.7.25
ip-10-0-38-100.eu-west-1.compute.internal   Ready    <none>   66m    v1.32.1-eks-5d632ec   10.0.38.100   <none>        Amazon Linux 2                 5.10.234-225.910.amzn2.aarch64    containerd://1.7.25

```

## Architecture

This project creates:

1. An EKS cluster in existing VPC using the [terraform-aws-modules/eks/aws](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) community module
2. A small managed node group for system workloads
3. Karpenter for node autoscaling using the [terraform-aws-modules/eks/aws//modules/karpenter](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest/submodules/karpenter) community module
4. Karpenter NodePools for both x86 and ARM instances
5. IAM roles and policies for Karpenter and EKS

## Requirements

- AWS CLI configured with appropriate credentials
- Terraform >= 1.3.2
- kubectl
- An existing VPC with public and private subnets

## Configuration

This project supports two approaches for configuring Karpenter node provisioning:

### 1. Using Discovery with Tags (Default)

By default, the project uses discovery based on the `karpenter.sh/discovery` tag to automatically find subnets and security groups

The project automatically adds the `karpenter.sh/discovery: <cluster_name>` tag to all resources, which Karpenter uses to discover subnets and security groups

Example configuration in `terraform.tfvars`:

```hcl
use_subnet_discovery         = true
use_security_group_discovery = true
```

### 2. Using Explicit Subnet IDs and Security Group IDs

Alternatively, you can use explicit subnet IDs and security group IDs for Karpenter node provisioning by setting the following variables to false

```hcl
# Disable discovery
use_subnet_discovery         = false
use_security_group_discovery = false
```

## Terraform Remote State Management

By default, the project uses local terraform state. If you wish to set up remote state, follow the instructions below.

### Use the Setup Script

Use the helper script to create the S3 bucket and DynamoDB table

```bash
# run with default settings (will use terraform-state-<account-id>-<region> as bucket name)
./scripts/setup-remote-state.sh
```

The script will:
1. Create an S3 bucket with versioning and encryption enabled
2. Create a DynamoDB table for state locking
3. Output the exact configuration to add to your `backend.tf` file

## Running Workloads on Specific Architectures

### Testing Karpenter Provisioning

Helper script to test Karpenter's node provisioning capabilities:

```bash
# Run the test script
./scripts/test-karpenter.sh
```

The script will:
1. Deploy test workloads for x86, ARM, and Spot instances
2. Monitor node provisioning
3. Show Karpenter events and deployment status
4. Provide cleanup commands

### Applying Example Deployments

```bash
# Apply a specific example
kubectl apply -f examples/architecture/nginx-x86.yaml
kubectl apply -f examples/architecture/nginx-arm64.yaml

# Apply all examples in a directory
kubectl apply -f examples/architecture/

# Apply all examples
kubectl apply -f examples/
```

### Running on x86/AMD64, ARM64/Graviton, Spot Instances

The `examples/` directory contains organized sample deployments for various use cases:

- **[Architecture-specific deployments](examples/architecture/)** - Run workloads on x86/AMD64 or ARM64/Graviton
- **[Spot instance deployments](examples/spot/)** - Run workloads on cost-effective Spot instances
- **[Specialized workloads](examples/specialized/)** - Deploy compute-optimized, memory-intensive, or workloads with tolerations
- **[High availability configurations](examples/high-availability/)** - PodDisruptionBudgets for ensuring availability

Each directory contains detailed README files with usage instructions and explanations.

## CleanUp

Before destroying the infrastructure with Terraform, it's important to properly clean up Karpenter resources to avoid issues during deletion.

```bash
# Scale down all deployments to 0
kubectl get deployments --all-namespaces -o json | jq -r '.items[] | .metadata.name + " " + .metadata.namespace' | while read -r name namespace; do
  kubectl scale deployment "$name" --replicas=0 -n "$namespace"
done

# Delete Karpenter resources
kubectl delete nodeclaims --all
kubectl delete nodepools --all
kubectl delete ec2nodeclasses.karpenter.k8s.aws --all

# If resources are stuck with finalizers, you can force remove them
kubectl patch nodepools <NODEPOOL_NAME> -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl patch ec2nodeclasses <EC2NODECLASS_NAME> -p '{"metadata":{"finalizers":[]}}' --type=merge

# Check for any remaining nodes
kubectl get nodes -o wide

# Clean up IAM policies from Karpenter node role
NODE_ROLE_NAME="Karpenter-eks-karpenter-demo"
POLICIES=$(aws iam list-attached-role-policies --role-name "$NODE_ROLE_NAME" --query "AttachedPolicies[].PolicyArn" --output text)

for POLICY_ARN in $POLICIES; do
  aws iam detach-role-policy --role-name "$NODE_ROLE_NAME" --policy-arn "$POLICY_ARN"
done
```

After running the cleanup commands, we can safely destroy the infrastructure:

```bash
terraform destroy
```

## Karpenter Version

This project uses Karpenter v1.3.1, which is the latest stable version with the v1 API.

For more information on the Karpenter v1 API, see the [Karpenter documentation](https://karpenter.sh/docs/).


### References

Used/adapted the following public sources from Github: https://github.com/altinukshini/eks-karpenter-example

