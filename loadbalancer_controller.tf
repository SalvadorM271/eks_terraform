/*testing new code-----------------------------------------------------------------*/

/*data is being used to create an AWS IAM policy document. This policy document is not actually creating
 the policy in AWS, it's just defining the policy in Terraform configuration. a resource block will later
 be use to create this on aws (a variable should be passed with the needed namespace, to make it better)*/ 

data "aws_iam_policy_document" "aws_load_balancer_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" // to make it better pass var for namespace
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"] // put your service acc name here and namespace wher it lives
      // rol is restricted to only be use by the service account define above by sub, check eks notes
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

// the name of the role is important to remmenber or to be created under a guideline since is use on kube too

resource "aws_iam_role" "aws_load_balancer_controller" {
  //the policy define with data is like a template for easy use we pass it here to create the policy
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role_policy.json
  name               = "aws-load-balancer-controller"
}

//another policy is needed but i use a file instead of doing everything here to make it redable

resource "aws_iam_policy" "aws_load_balancer_controller" {
  policy = file("./alb_pol/AWSLoadBalancerController.json")
  name   = "AWSLoadBalancerController"
}

// attaching the policy to the rol created bf

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attach" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

// outputing the rol arn (you can get by just knowing the acc number and the name of the role)

output "aws_load_balancer_controller_role_arn" {
  value = aws_iam_role.aws_load_balancer_controller.arn
}

// after creating the rol in aws there is two options to deploy either creating a helm release or a kubemanifest

/* now lets deploy it to the eks cluster. i decided to do this with terraform since this goes on kube-system 
namespace unlike the external dns which is created for each namespace*/

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.demo.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.demo.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.demo.id]
      command     = "aws"
    }
  }
}

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
    value = aws_iam_role.aws_load_balancer_controller.arn // name is very important be sure to not change
  }

  depends_on = [
    aws_eks_node_group.private-nodes,
    aws_iam_role_policy_attachment.aws_load_balancer_controller_attach
  ]
}

