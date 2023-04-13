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
      values   = ["system:serviceaccount:kube-system:${var.project_name}-eks-csi-sa-${var.environment}"] // put your service acc name here and namespace wher it lives
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
  name        = "${var.project_name}-eks-csi-pol-${var.environment}"
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

// create service account for efs csi driver (this will be created on current cluster thx to state)

resource "kubernetes_service_account" "efs_csi_controller_sa" {
  metadata {
    name      = "${var.project_name}-eks-csi-sa-${var.environment}"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.efs_csi_rol.arn
    }
  }
}

// deploy efs csi driver controller in eks cluster

resource "helm_release" "aws_efs_csi_driver" {
  name       = "${var.project_name}-aws-efs-csi-driver-${var.environment}"
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

// create EFS volume for jenkins (you may use it for other things)

resource "aws_efs_file_system" "efs_vol" {
  creation_token = "${var.project_name}-efs_vol-${var.environment}"

  tags = {
    Name = "efs_vol"
  }
}

// -----------------------

// creates security group to allow traffic btw efs and node group

resource "aws_security_group" "efs_sg" {
  name        = "${var.project_name}-efs-sg-${var.environment}"
  description = "EFS Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 2049 # NFS (Network File System) port
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  tags = {
    Name = "efs-sg"
  }
}

// create local to avoid repetition of mount code (only add subnets were node group is deploy)

locals {
  subnet_ids = [
    aws_subnet.private-us-east-1a.id,
    aws_subnet.private-us-east-1b.id,
  ]
}

// mounts efs on each worker node on the node group

resource "aws_efs_mount_target" "efs_vol" {
  count           = length(local.subnet_ids) // result of count is 2 so two resources are created
  file_system_id  = aws_efs_file_system.efs_vol.id
  subnet_id       = local.subnet_ids[count.index] // loops through every subnet
  security_groups = [aws_security_group.efs_sg.id] 
}