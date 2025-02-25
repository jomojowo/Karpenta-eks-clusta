resource "kubectl_manifest" "karpenter_nodepool" {
  yaml_body = <<YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: x86-arm64-nodepool
spec:
  template:
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: x86-arm64-nodeclass
      requirements:
        - key: "kubernetes.io/os"
          operator: In
          values: ["linux"]
        - key: kubernetes.io/arch
          operator: In
          values:
            - amd64
            - arm64
        - key: "karpenter.k8s.aws/instance-family"
          operator: In
          values: ["t4g", "m7g", "m5","m5d","c5","c5d","c4","r4"]
        - key: "karpenter.k8s.aws/instance-cpu"
          operator: In
          values: ["4", "8", "16", "32"]
        - key: "karpenter.k8s.aws/instance-generation"
          operator: Gt
          values: ["2"]
        - key: "karpenter.sh/capacity-type"
          operator: In
          values: ["spot"]
      limits:
        cpu: "1000"
      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: 30s
YAML
  wait = true
  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "karpenter_nodeclass" {
  yaml_body = <<YAML
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: x86-arm64-nodeclass
spec:
  amiSelectorTerms:
    - alias: al2@latest
  instanceProfile: ${aws_iam_instance_profile.karpenter_node_instance_profile.name}
  subnetSelectorTerms:
    - id: ${join("\n    - id: ", var.cluster_vpc_subnets)}
  securityGroupSelectorTerms:
    - tags:
        kubernetes.io/cluster/${var.cluster_name}: "owned"
  instanceMarketOptions:
    marketType: "spot"
YAML

  wait = true
  depends_on = [kubectl_manifest.karpenter_nodepool]
}

resource "aws_eks_access_entry" "karpenter_node_access" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.karpenter_node_role.arn
  type = "EC2_LINUX"

  depends_on = [kubectl_manifest.karpenter_nodeclass]
}
