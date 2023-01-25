## creates rol needed for load balancer controller
resource "aws_iam_role" "load_balancer_controller" {
  name = "load_balancer_controller"

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

## attaches the needed policies to the rol

resource "aws_iam_role_policy_attachment" "load_balancer_controller-AmazonEKSLoadBalancerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancerPolicy"
  role = aws_iam_role.load_balancer_controller.name
}

resource "aws_iam_role_policy_attachment" "load_balancer_controller-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.load_balancer_controller.name
}

## creates the services account in kubernetes, there is no rol directly bound to the service account
## however the service account is used by the deployment to make use of the IAM rol i created

resource "kubernetes_service_account" "load_balancer_controller" {
  metadata {
    name      = "load_balancer_controller"
    namespace = "kube-system"
  }
}


## now i can deploy the load balancer controller

resource "kubernetes_deployment" "load_balancer_controller" {
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
        service_account_name = kubernetes_service_account.load_balancer_controller.metadata.0.name
        containers {
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
            value = aws_iam_role.load_balancer_controller.arn ## the IAM rol i created
          }
        }
      }
    }
  }
}


