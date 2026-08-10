apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: compute-heavy
spec:
  template:
    metadata:
      labels:
        node-type: karpenter
        workload: compute-heavy
    spec:
      nodeClassRef:
        apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
        name: default
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: [
            "c6i.large",
            "c6i.xlarge", 
            "c6i.2xlarge",
            "c6i.4xlarge",
            "m6i.xlarge",
            "m6i.2xlarge",
            "m6i.4xlarge",
            "r6i.xlarge",
            "r6i.2xlarge"
          ]
      taints:
        - key: workload
          value: "compute-heavy"
          effect: "NoSchedule"
  limits:
    cpu: 200
    memory: 500Gi
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s
    expireAfter: 4h