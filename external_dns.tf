// new code

/*data is being used to create an AWS IAM policy document. This policy document is not actually creating
 the policy in AWS, it's just defining the policy in Terraform configuration. a resource block will later
 be use to create this on aws (a variable should be passed with the needed namespace)*/ 

data "aws_iam_policy_document" "external_dns_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition { // uses open id connect provider to be created so no need to edit for multi env
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" // pass var for na
      values   = ["system:serviceaccount:default:external-dns"] // same name needed on sa <--- check
      // its of extremelly importance for you to check if the service acc was deploy on same namespace and has the same name since you are restricting access for this rol to only that service acc
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
  name               = "external-dns-${var.environment}"
}

//another policy is needed but i use a file instead of doing everything here to make it redable

resource "aws_iam_policy" "external-dns" {
  policy = file("./dns_pol/external-dns.json")
  name   = "${var.project_name}-ext-dns-pol-${var.environment}"
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


//---------------------policy to use secrets manager-------------------------

resource "aws_iam_policy" "eks_csi_driver_policy" {
  name        = "${var.project_name}-secrets-pol-${var.environment}"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        /*you need to specify the arn of the secret you want to use in the app if you need
        more than one you can use a comma and if you need them all you can use
        arn:aws:secretsmanager:*:*:secret:*(not tested)*/
        Resource = ["arn:aws:secretsmanager:us-east-1:438555236323:secret:cloudflare-8ACs61"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external-dns_attach_secrets" {
  role       = aws_iam_role.external-dns.name
  policy_arn = aws_iam_policy.eks_csi_driver_policy.arn
}

// all the resources below are not needed if helm chart is not use

data "aws_secretsmanager_secret" "cloudflare_credentials" {
  name = "cloudflare"
}

data "aws_secretsmanager_secret_version" "cloudflare_credentials" {
  secret_id = data.aws_secretsmanager_secret.cloudflare_credentials.id
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "external-dns"
  version    = "6.28.1"

  namespace = "default"

  set {
    name = "provider"
    value = "cloudflare"
  }

  set {
    name = "cloudflare.email"
    value = jsondecode(data.aws_secretsmanager_secret_version.cloudflare_credentials.secret_string)["cloudflare_email"]
  }

  set {
    name = "cloudflare.apiKey"
    value = jsondecode(data.aws_secretsmanager_secret_version.cloudflare_credentials.secret_string)["cloudflare_key"]
  }

  depends_on = [aws_eks_node_group.private-nodes]

}

















