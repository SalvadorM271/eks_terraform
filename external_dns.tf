##-------------------only need this if im using external dns in my kubernetes--------------------
/*
## creates rol needed for external dns this is not bind to anything, bc The "assume_role_policy" for this role
## is configured to allow the "eks.amazonaws.com" service to assume it, so that service
## can perform actions on your behalf with the permissions granted by the policies attached to the role.

resource "aws_iam_role" "externaldns" {
  name = "externaldns"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

## attaches policies needed for external dns to my rol

resource "aws_iam_role_policy_attachment" "externaldns-AmazonRoute53AutoNamingPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53AutoNamingFullAccess"
  role = aws_iam_role.externaldns.name
}


resource "aws_iam_role_policy_attachment" "externaldns-AmazonEC2ReadOnlyAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  role = aws_iam_role.externaldns.name
}


## better to just use kube manifest for this bc if they are already created
## they wont create again unless something changes
*/
##-------------------------------------------------------------------------------------------


// new code

/*data is being used to create an AWS IAM policy document. This policy document is not actually creating
 the policy in AWS, it's just defining the policy in Terraform configuration. a resource block will later
 be use to create this on aws (a variable should be passed with the needed namespace)*/ 

data "aws_iam_policy_document" "external_dns_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" // pass var for na
      values   = ["system:serviceaccount:kube-system:external-dns"] // same name needed on sa
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

// the name of the role is important to remmenber or to be created under a guideline since is use on kube too

resource "aws_iam_role" "external-dns" {
  //the policy define with data is like a template for easy use we pass it here to create the policy
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role_policy.json
  name               = "external-dns"
}

//another policy is needed but i use a file instead of doing everything here to make it redable

resource "aws_iam_policy" "external-dns" {
  policy = file("./dns_pol/external-dns.json")
  name   = "external-dns"
}

// attaching the policy to the rol created bf

resource "aws_iam_role_policy_attachment" "external-dns_attach" {
  role       = aws_iam_role.external-dns.name
  policy_arn = aws_iam_policy.external-dns.arn
}

// outputing the rol arn (you can get by just knowing the acc number and the name of the role)

output "external-dns_role_arn" {
  value = aws_iam_role.external-dns.arn
}


// after creating the rol in aws there is two options to deploy either creating a helm release or a kubemanifest


/*
resource "kubernetes_service_account" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external-dns.arn
    }
  }
  automount_service_account_token = true
}

resource "kubernetes_cluster_role" "external_dns" {
  metadata {
    name = "external-dns"
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions","networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get","watch","list"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "external_dns" {
  metadata {
    name = "external-dns"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.external_dns.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.external_dns.metadata.0.name
    namespace = kubernetes_service_account.external_dns.metadata.0.namespace
  }
}

// change to dns

resource "helm_release" "aws-load-balancer-controller" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.4.1"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.demo.id
  }

  set {
    name  = "image.tag"
    value = "v2.4.2"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller" // creates service account
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn" // passes anotation to sa
    value = aws_iam_role.external-dns.arn // name is very important be sure to not change
  }

  depends_on = [
    aws_eks_node_group.private-nodes,
    aws_iam_role_policy_attachment.external-dns_attach
  ]
}*/

















