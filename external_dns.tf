##-------------------only need this if im using external dns in my kubernetes--------------------

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


## creates service account on kubernetes

resource "kubernetes_service_account" "externaldns" {
  metadata {
    name      = "externaldns"
    namespace = "externaldns"
  }
}

## creates rol in kubernetes needed to perform operations within kubernetes

resource "kubernetes_cluster_role" "externaldns" {
  metadata {
    name = "externaldns-role"
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["patch", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["create", "get", "list", "watch", "update"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "list", "watch"]
  }
}


## binds kubernetes cluster rol to service account

resource "kubernetes_role_binding" "externaldns" {
  metadata {
    name      = "externaldns"
    namespace = "externaldns"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "externaldns-role"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.externaldns.metadata.0.name
    namespace = kubernetes_service_account.externaldns.metadata.0.namespace
  }
}

## makes external dns work with cloudflare 

resource "kubernetes_config_map" "externaldns" {
  metadata {
    name      = "externaldns"
    namespace = "externaldns"
  }

  data = {
    "provider" = "cloudflare"
    "cloudflare_api_key" = "YOUR_API_KEY" ## change for my value
    "cloudflare_email" = "your_email@example.com" ## change for my value
    "openid_provider_arn" = "${aws_iam_openid_connect_provider.eks.arn}" ## can be found on main.tf
    "policy" = "upsert-only"
    "registry" = "txt"
  }
}

## deployment for the external dns image

resource "kubernetes_deployment" "externaldns" {
  metadata {
    name      = "externaldns"
    namespace = "externaldns"
  }

  spec {
    replicas = 1

    template {
      metadata {
        labels = {
          "app" = "externaldns"
        }
      }

      spec {
        container {
          name  = "externaldns"
          image = "registry.docker.io/bitnami/external-dns:latest"

          env {
            name  = "POD_NAME"
            value = "${kubernetes_pod.externaldns.metadata.0.name}"
          }

          env {
            name  = "POD_NAMESPACE"
            value = "${kubernetes_pod.externaldns.metadata.0.namespace}"
          }

          volume_mount {
            name = "config"
            mount_path = "/etc/externaldns"
          }
        }

        volume {
          name = "config"
          config_map {
            name = "externaldns"
          }
        }
      }
    }
  }
}


/* this is created with kube manifest

resource "kubernetes_service" "externaldns" {
  metadata {
    name      = "externaldns"
    namespace = "externaldns"
  }

  spec {
    selector = {
      "app" = "externaldns"
    }
    ports {
      name     = "http"
      port     = 80
      protocol = "TCP"
    }
  }
}

//p5

resource "kubernetes_ingress" "externaldns" {
  metadata {
    name      = "externaldns"
    namespace = "externaldns"
  }

  spec {
    rules {
      host = "externaldns.example.com"

      http {
        paths {
          path = "/"

          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.externaldns.metadata.0.name
              port = {
                name = "http"
              }
            }
          }
        }
      }
    }
  }
}

*/

