resource "aws_iam_role" "karpenter_node_role" {
  name  = "KarpenterNodeRole-${var.cluster_name}"
  #IAM node role that will be passed to new nodes created by karpenter.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow"
        Principal = {
          "Service": "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssmInstanceCore-role-policy-attach" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = data.aws_iam_policy.AddSSMManagedInstanceCorePolicy.arn
}

resource "aws_iam_role_policy_attachment" "Eks-cni-role-policy-attach" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = data.aws_iam_policy.AmazonEKS_CNI_Policy.arn
}

resource "aws_iam_role_policy_attachment" "eks-workernode-role-policy-attach" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = data.aws_iam_policy.AmazonEKSWorkerNodePolicy.arn
}

resource "aws_iam_role_policy_attachment" "ecr-readonly-role-policy-attach" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = data.aws_iam_policy.AmazonEC2ContainerRegistryReadOnly.arn
}

resource "aws_iam_instance_profile" "karpenter_node_instance_profile" {
  role = aws_iam_role.karpenter_node_role.name
  name = "KarpenterNodeInstanceProfile-${var.cluster_name}"
}
