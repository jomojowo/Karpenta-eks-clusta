#Creating IAM role for Karpenter's Service-Account that are in an EKS cluster

data "aws_iam_policy_document" "controller_irsa_policy" {
  statement {
    sid     = "Karpenter"
    effect  = "Allow"
    actions = [
      "ssm:GetParameter",
      "ec2:DescribeImages",
      "ec2:RunInstances",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeAvailabilityZones",
      "ec2:DeleteLaunchTemplate",
      "ec2:CreateTags",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateFleet",
      "ec2:DescribeSpotPriceHistory",
      "pricing:GetProducts",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid     = "ConditionalEC2Termination"
    effect  = "Allow"
    actions = [
      "ec2:TerminateInstances",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid     = "PassNodeIAMRole"
    effect  = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/KarpenterNodeRole-${var.cluster_name}",
    ]
  }

  statement {
    sid     = "EKSClusterEndpointLookup"
    effect  = "Allow"
    actions = [
      "eks:DescribeCluster",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/KarpenterNodeRole-${var.cluster_name}",
    ]
  }

  statement {
    sid     = "AllowScopedInstanceProfileCreationActions"
    effect  = "Allow"
    actions = [
      "iam:CreateInstanceProfile",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid     = "AllowScopedInstanceProfileTagActions"
    effect  = "Allow"
    actions = [
      "iam:TagInstanceProfile",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid     = "AllowScopedInstanceProfileActions"
    effect  = "Allow"
    actions = [
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:DeleteInstanceProfile",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid     = "AllowInstanceProfileReadActions"
    effect  = "Allow"
    actions = [
      "iam:GetInstanceProfile",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid     = "CreateServiceLinkedRoleForEC2Spot"
    effect  = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole",
    ]
    resources = [
      "arn:aws:iam::*:role/aws-service-role/spot.amazonaws.com/AWSServiceRoleForEC2Spot",
    ]
  }
}

resource "aws_iam_role" "karpenter_irsa_role" {
  name  = "karpenter_iam_role"
  #allow federated role assumption using webIdentity(oidc)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          "StringLike" = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:${var.karpenter_namespace}:${var.karpenter_sa_name}",
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
      }
    ]
  })

  depends_on = [aws_iam_instance_profile.karpenter_node_instance_profile]
}

resource "aws_iam_policy" "karpenter" {
  policy      = data.aws_iam_policy_document.controller_irsa_policy.json
  name        = "${var.cluster_name}-karpenter-controller-policy"
  path        = "/"
}

resource "aws_iam_role_policy_attachment" "karpenter" {
  role       = aws_iam_role.karpenter_irsa_role.name
  policy_arn = aws_iam_policy.karpenter.arn
}


resource "kubectl_manifest" "karpenter_sa" {
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${var.karpenter_sa_name}
  namespace: ${var.karpenter_namespace}
  annotations:
    eks.amazonaws.com/role-arn: "${aws_iam_role.karpenter_irsa_role.arn}"
YAML

  depends_on = [helm_release.karpenter]
}