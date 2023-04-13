// installing EFS CSI driver (so efs can work on an eks cluster)

// IAM rol for EFS csi

data "aws_iam_policy_document" "efs_csi_rol_doc" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    // the condition block is the only one that needs changing to create a document for other controllers

    condition { // uses open id connect provider to be created so no need to edit for multi env
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" // to make it better pass var for namespace
      values   = ["system:serviceaccount:kube-system:efs-csi-controller-sa"] // put your service acc name here and namespace wher it lives
      // rol is restricted to only be use by the service account define above by sub, check eks notes
    }

    // same oicd

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "efs_csi_rol" {
  //the policy define with data is like a template for easy use we pass it here to create the policy
  assume_role_policy = data.aws_iam_policy_document.efs_csi_rol_doc.json
  name               = "${var.project_name}-eks-csi-rol-${var.environment}"
}

// efs csi policy

resource "aws_iam_policy" "efs_csi_driver" {
  name        = "EfsCsiDriverPolicy"
  description = "Policy for the EFS CSI driver to communicate with EFS resources."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:CreateAccessPoint",
          "elasticfilesystem:DeleteAccessPoint"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

// attach created policy to created rol

resource "aws_iam_role_policy_attachment" "efs_csi_attach_pol" {
  role       = aws_iam_role.efs_csi_rol.name
  policy_arn = aws_iam_policy.efs_csi_driver.arn
}

// create service account for efs csi driver

resource "kubernetes_service_account" "efs_csi_controller_sa" {
  metadata {
    name      = "efs-csi-controller-sa"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.efs_csi_rol.arn
    }
  }
}

// deploy efs csi driver controller in eks cluster

resource "helm_release" "aws_efs_csi_driver" {
  name       = "aws-efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart      = "aws-efs-csi-driver"
  namespace  = "kube-system"

  set {
    name  = "controller.serviceAccount.create"
    value = "false"
  }
  set {
    name  = "controller.serviceAccount.name"
    value = kubernetes_service_account.efs_csi_controller_sa.metadata[0].name
  }
}

// create EFS volume for jenkins (you may create other efs volumens if needed)

resource "aws_efs_file_system" "jenkins" {
  creation_token = "${var.project_name}-jenkins-efs-${var.environment}"

  tags = {
    Name = "jenkins-efs"
  }
}