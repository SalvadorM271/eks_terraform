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















/*
## creates service account on kubernetes

resource "kubernetes_service_account" "externaldns" {
  metadata {
    name      = "externaldns"
    namespace = "default"
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


## binds kubernetes cluster rol to service account

resource "kubernetes_role_binding" "externaldns" {
  metadata {
    name      = "externaldns"
    namespace = "default"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "externaldns-role" ## cluster role name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "externaldns" ## service account name
    namespace = "default"
  }
} 



## deployment for the external dns image

resource "kubernetes_deployment" "externaldns" {
  metadata {
    name      = "externaldns"
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = "externaldns"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "externaldns"
        }
      }

      spec {
        service_account_name = "externaldns"
        container {
          name  = "externaldns"
          image = "registry.k8s.io/external-dns/external-dns:v0.13.1"
          args = ["--provider=cloudflare", "--source=service", "--source=ingress"]

          env {
            name  = "CF_API_KEY"
            value = ""
          }

          env {
            name  = "CF_API_EMAIL"
            value = ""
          }

        }

        security_context {
            fs_group = 65534 ## For ExternalDNS to be able to read Kubernetes and AWS token files
        }

      }
    }
  }
}

*/




