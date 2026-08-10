provider "aws" {
  region = var.region
}

locals {
  cluster_name = "${var.project}-eks"
  account_id = data.aws_caller_identity.current.account_id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.eks_version

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]  
  cloudwatch_log_group_retention_in_days = 3

  vpc_id          = var.vpc_id
  subnet_ids      = var.private_subnet_ids

  cluster_endpoint_public_access = true
  enable_irsa = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_group_defaults = {
    ami_type        = "AL2023_x86_64_STANDARD"
    instance_type   = var.instance_type
    desired_size    = var.autoscaling_policy.desired_capacity
    min_size        = var.autoscaling_policy.min_size
    max_size        = var.autoscaling_policy.max_size
    security_groups = [var.rds_security_group_id]
  }

  eks_managed_node_groups = {
    eks_nodes = {
      desired_size     = var.autoscaling_policy.desired_capacity
      min_size         = var.autoscaling_policy.min_size
      max_size         = var.autoscaling_policy.max_size
      instance_types   = [var.instance_type]
      subnets          = var.private_subnet_ids
      iam_role_arn     = aws_iam_role.eks_nodes_role.arn
      create_iam_role  = false
    }
  }

  tags = {
    "karpenter.sh/discovery" = local.cluster_name
    "datadog" = "true"
  }

}

module "lb_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"
  role_name                              = "${var.project}_eks_lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

module "eks_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name                     = "${var.project}-eks-access-role"
  role_policy_arns              = {
                     policy = aws_iam_policy.eks_access.arn
                     }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["default:${var.project}-access-service-account", "backend:${var.project}-access-service-account", "oidc:${var.project}-access-service-account"]
    }
  }
  depends_on = [kubernetes_namespace.namespace_backend]
}

resource "kubernetes_namespace" "namespace_backend" {
  metadata {
    name = "backend"
  }
}


resource "kubernetes_service_account" "eks_service_account" {
  metadata {
    name      = "${var.project}-access-service-account"
    namespace = "backend"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.eks_irsa.iam_role_arn
    }
  }
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy_attachment" {
  role       = aws_iam_role.eks_nodes_role.id
  # data.aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

#resource "aws_iam_policy" "ebs_csi_policy" {
#  name        = "${var.project}-ebs-csi-policy"
#  description = "IAM policy for EBS CSI driver"
#  policy      = file("iam-policy.json")
#}

#resource "aws_iam_role_policy_attachment" "eks_node_ebs_csi_policy" {
#  policy_arn = aws_iam_policy.ebs_csi_policy.arn
#  role       = module.eks.eks_managed_node_groups["cwvm"].iam_role_name
#}


data "aws_eks_cluster_auth" "this" {
  name = local.cluster_name
}

data "aws_caller_identity" "current" {}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}


resource "kubernetes_service_account" "service-account" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.lb_role.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
  depends_on = [ module.eks ]
}

resource "kubernetes_service_account" "oidc_service_account" {
  metadata {
    name      = "${var.project}-access-service-account"
    namespace = "oidc"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.eks_irsa.iam_role_arn
    }
  }
}

resource "helm_release" "alb-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  depends_on = [
     kubernetes_service_account.service-account
  ]

    set {
     name  = "region"
     value = var.region
    }

    set {
     name  = "vpcId"
     value = var.vpc_id
    }

    set {
     name  = "image.repository"
     value = "602401143452.dkr.ecr.${var.region}.amazonaws.com/amazon/aws-load-balancer-controller"
    }

    set {
     name  = "serviceAccount.create"
     value = "false"
    }

    set {
     name  = "serviceAccount.name"
     value = "aws-load-balancer-controller"
    }

    set {
     name  = "clusterName"
     value = local.cluster_name
    }
}


resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = var.eks_metric_version

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls" 
    }
}

resource "kubernetes_storage_class_v1" "ebs_retain" {
  metadata {
    name = "ebs-oidc"
  }

  storage_provisioner = "ebs.csi.aws.com"
  
  parameters = {
    type       = "gp3"
    encrypted  = "true"
    fsType     = "ext4"
    iops       = "3000"
    throughput = "125"
  }

  reclaim_policy         = "Retain"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

}
