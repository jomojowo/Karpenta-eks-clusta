data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

data "aws_iam_policy" "AddSSMManagedInstanceCorePolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

  depends_on = [aws_iam_role.karpenter_node_role]
}


data "aws_iam_policy" "AmazonEKSWorkerNodePolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"

  depends_on = [aws_iam_role.karpenter_node_role]
}

data "aws_iam_policy" "AmazonEKS_CNI_Policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"

  depends_on = [aws_iam_role.karpenter_node_role]
}

data "aws_iam_policy" "AmazonEC2ContainerRegistryReadOnly" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"

  depends_on = [aws_iam_role.karpenter_node_role]
}
