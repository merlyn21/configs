terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.0.0"

  cluster_name           = local.cluster_name
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  
  create_node_iam_role   = false
  node_iam_role_arn      = aws_iam_role.eks_nodes_role.arn
  create_access_entry = false

  enable_irsa            = true
  create_instance_profile = true
}

provider "aws" {
  alias  = "virginia" 
  region = "us-east-1"
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter" 
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "0.37.0"
  

  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password

  values = [
    <<-EOT
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
    nodeClassRef:
      apiVersion: karpenter.k8s.aws/v1beta1
      kind: EC2NodeClass
    EOT
  ]

  depends_on = [
    module.eks,
    module.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = templatefile("${path.module}/templates/karpenter-ec2nodeclass.yaml.tpl", {
    cluster_name                = local.cluster_name
    eks_version                 = var.eks_version
    environment                 = "test"
    node_instance_profile_name  = module.karpenter.instance_profile_name
    sg_name                     = module.eks.node_security_group_id
  })

  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = templatefile("${path.module}/templates/karpenter-nodepool.yaml.tpl", {
    ec2_type = var.instance_type
  })

  depends_on = [
    helm_release.karpenter,
    kubectl_manifest.karpenter_node_class
  ]
}

resource "kubectl_manifest" "karpenter_compute_heavy_node_pool" {
  yaml_body = file("${path.module}/templates/karpenter-compute-heavy-nodepool.yaml.tpl")
  
  depends_on = [
    helm_release.karpenter,
    kubectl_manifest.karpenter_node_class
  ]
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}
