/* was a work in progress wanna try something else
## creates rol needed for load balancer controller
resource "aws_iam_role" "load-balancer-controller" {
  name = "load-balancer-controller"

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

## creating and attaching the needed policies to the rol

resource "aws_iam_policy" "eks_alb_policy" {
  name        = "eks_alb_policy"
  description = "policy for eks to be able to create alb"
  policy = file("./alb_pol/iam_policy_latest.json")
}

resource "aws_iam_role_policy_attachment" "alb_for_eks" {
  policy_arn = aws_iam_policy.eks_alb_policy.policy_arn
  role = aws_iam_role.load-balancer-controller.name
}

## creates service account on kube-system namespace kubernetes

resource "kubernetes_service_account" "alb" {
  metadata {
    name      = "alb"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.load-balancer-controller.arn
    }
  }
  automount_service_account_token = true
}

## uses helm to deploy application load balancer

resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = "kube-system"
  wait       = true
  repository = "602401143452.dkr.ecr.us-east-1.amazonaws.com/amazon/aws-load-balancer-controller"
  chart      = "eks/aws-load-balancer-controller"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.demo.name
  }

  set {
    name  = "serviceAccount.create"
    value = false
  }

  set {
    name  = "serviceAccount.name"
    value = "alb" ## it wasnt picking the reference
  }

  set {
    name  = "region"
    value = "us-east-1"
  }

  set {
    name  = "vpcId"
    value = aws_vpc.main.id
  }

  set {
    name  = "provider"
    value = "aws"
  }

  set_string {
    name  = "policy"
    value = "sync"
  }

  set_string {
    name  = "logLevel"
    value = var.external_dns_chart_log_level
  }

  set {
    name  = "sources"
    value = "{ingress,service}"
  }

  set {
    name  = "domainFilters"
    value = "{${join(",", var.external_dns_domain_filters)}}"
  }

  set_string {
    name  = "aws.zoneType"
    value = var.external_dns_zoneType
  }

  set_string {
    name  = "aws.region"
    value = var.aws_region
  }
}was a work in progress wanna try something else*/


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
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" // pass var for na
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"] // same name needed on sa
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































## better to just use kube manifest for this bc if they are already created
## they wont create again unless something changes

/*

## creates the services account in kubernetes, there is no rol directly bound to the service account
## however the service account is used by the deployment to make use of the IAM rol i created

resource "kubernetes_service_account" "load-balancer-controller" {
  metadata {
    name      = "load-balancer-controller"
    namespace = "kube-system"
  }
}


## now i can deploy the load balancer controller

resource "kubernetes_deployment" "load-balancer-controller" {
  metadata {
    name      = "load-balancer-controller"
    namespace = "kube-system"
    labels = {
        "app" = "load-balancer-controller"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app" = "load-balancer-controller"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "load-balancer-controller"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.load-balancer-controller.metadata.0.name
        container {
          name  = "load-balancer-controller"
          image = "amazon/aws-load-balancer-controller:v1.1.0"
          env {
            name = "AWS_REGION"
            value = "us-east-1"
          }
          env {
            name = "AWS_ACCESS_KEY_ID"
            value = "access_key"
          }
          env {
            name = "AWS_SECRET_ACCESS_KEY"
            value = "secret_key"
          }
          env {
            name = "AWS_ROLE_ARN"
            value = aws_iam_role.load-balancer-controller.arn ## the IAM rol i created
          }
        }
      }
    }
  }
}

*/


