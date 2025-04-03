# Questions from Nir Krautammer
via Slack

Hi @Miro Adamy, I have a couple of questions please,

1) I see that you chose to use the IRSA pods authentication approach. Is there another way? and which approach is better in your opinion?

2) Is it necessary to deploy karpenter_crds separately after deploying Karpenter via the Helm chart?

3) Why do we need to configure repository_username & repository_password in Karpenter installation?

4) Why did you choose to use the tpl format to deploy EC2NodeClass ?

5) Is there a way to create a dependency between the NodePool & EC2NodeClass resources without explicitly adding the depends_on argument?

Thanks in advanced

## Answers

### 1) I see that you chose to use the IRSA pods authentication approach. Is there another way? and which approach is better in your opinion?

 IRSA refers to IAM Roles for Service Accounts in Amazon EKS. It is a mechanism that allows Kubernetes pods running in an EKS cluster to assume AWS IAM roles securely and access AWS resources without needing to manage long-term credentials.

IRSA is typically used in the following scenarios:

a) Karpenter: Karpenter requires an IAM role to interact with AWS services like EC2 for provisioning nodes. This role is associated with a Kubernetes service account using IRSA.

b) Other AWS-integrated Kubernetes workloads: For example, workloads that need access to S3, DynamoDB, or other AWS services.

IRSA allows Kubernetes service accounts to assume IAM roles securely.

Karpenter needs AWS access (== assume role with needed permissions) to work. It is possible not to use IRSA and assign the role e.g. by using EC2 Instance Roles - all code running on the instance will "inherit" these permissions. It requires:

- create appropriate roles for Karpenter (with permission like manage EC2, autoscaling) and attach it to instance profiles of the EKS nodes
- use node selectors / taints to make sure Karpenter pods run only on nodes with these roles attached

We generally always went for IRSA if possible as it is more granular and more secure (IMHO) and better defendable being the best practice.

The justified use cases for not using IRSA

- legacy clusters/distros where OIDC is not supported and deploying Karpenter there (== not creating EKS with Karpenter as in this case)

- AWS accounts where there are SCPs / IAM policies blocking OIDC setup or setup team lacks permissions. Usually compliance reasons or over-zelous security team blocks it (kinda ironic as it leads to less secure setup in the end). I have been through some of these scenarios before

- network restrictions where EKS cannot reach out to OIDC (airgapped systems)

- unsupported region

- throw away POC where security is not a concern (see below)

Technically there are more approaches to avoid IRSA / OIDC but one is potentially bad and one is terrible

a) (potentially bad) - custom authentication. Unless there is a very good use case, complexity, effort required, fragility, maintenance cost and potential security risks makes this a bad idea

b) static credentials - Kubernetes secrets or env var. Terrible idea, highly discouraged by any AWS recommendation, but it will do the job: Karpenter pod will receive the AWS permissions


### 2) Is it necessary to deploy karpenter_crds separately after deploying Karpenter via the Helm chart?

Technically not, as the Karpenter Helm chart already includes the CRDs required for Karpenter to function, and they are installed automatically when the chart is applied. However - it seems to be a best practice as many examples I have seen use this approach. One possible reason can be to split the lifecycles of CRD and Karpenter - by default, Helm does not upgrade or delete CRDs during chart upgrades or uninstalls. Deploying CRDs separately ensures they are managed explicitly and avoids potential issues during upgrades or rollbacks.

In this case, as Karpenter resources (e.g., NodePool, EC2NodeClass) depend on the CRDs being present in the cluster, deploying the CRDs separately (made explicit by depends_on) ensures they are available before the main Karpenter Helm release is applied.

I believe that Helm will not clean up CRDs by default on uninstall which is another potential issue from maintainability POV.

### 3) Why do we need to configure repository_username & repository_password in Karpenter installation?

It is recommended, even if the registry is public. I think that the main reason may be that all unauthenticated requests are more likely to hit rate limits on pulls, so providing credentials should be safer / faster. 

### 4) Why did you choose to use the tpl format to deploy EC2NodeClass ?

The example that I used as base for solution (see README) used it and I did not see a reason to change it. The conditional feature of template is nice and useful. 

I personally like templates, we used it a lot in my previous projects, we even had a template repositories that generated Terraform repositories by running Github Actions (based on a parameter file) and that generated TF repo was then used to as a start to build infra (different set of modules was included / modified based on param file).

As with everything there are pros and cons: dynamic generation, not mixing YAML and TF code syntax, variable injection, reusability, readability - versus more complexity (if overdone with ifs), less validation / linting etc, lack of dynamic blocks etc.

In this particular case, probably unnecessary, but IMHO nothing wrong with it.

### 5) Is there a way to create a dependency between the NodePool & EC2NodeClass resources without explicitly adding the depends_on argument?

Yes, Terraform automatically creates dependencies when one resource references another. If we ensure that the NodePool references an attribute of the EC2NodeClass, Terraform will handle the dependency.

There are multiple ways how to do that, e.g. when c

```tf
resource "kubectl_manifest" "karpenter_ec2nodeclass" {
  for_each = var.karpenter.node_pools

  yaml_body = <<-YAML
apiVersion: karpenter.k8s.aws/v1alpha1
kind: EC2NodeClass
metadata:
  name: ${each.value.name}
spec:
  ...
YAML
}

resource "kubectl_manifest" "karpenter_node_pool" {
  for_each = var.karpenter.node_pools

  yaml_body = <<-YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: ${each.value.name}
spec:
  template:
    spec:
      nodeClassRef:
        kind: EC2NodeClass
        name: ${kubectl_manifest.karpenter_ec2nodeclass[each.key].metadata[0].name} # Reference corresponding EC2NodeClass
        group: karpenter.k8s.aws
  ...
YAML
}
```

It seems that using explicit dependencies is not as popular these days (it overrides the default). My personal preference (based on Zen of Python) is `Explicit is better than implicit` - it helps the maintainers of the code to lower the cognitive load, which is a real problem of current DevOps / Platform engineering industry

