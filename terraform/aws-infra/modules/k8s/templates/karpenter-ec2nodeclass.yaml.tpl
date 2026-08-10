apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2023
  amiSelectorTerms:
    - name: "amazon-eks-node-al2023-x86_64-standard-${eks_version}-*"
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${cluster_name}"
  securityGroupSelectorTerms:
    - id: "${sg_name}"

  instanceProfile: "${node_instance_profile_name}"
  tags:
    Name: "karpenter-node-${cluster_name}"
    Environment: "${environment}"
    "karpenter.sh/discovery": "${cluster_name}"
    datadog: "true"

