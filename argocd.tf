/* NO NEED to edit this one since im using diferrent tfvars file and different workspaces for my state 
terraform will deploy this in the right cluster, see eks notes*/

// helm provider already define in loadbalancer_controller.tf
/*
// creates argo cd namespace

resource "kubernetes_namespace" "argo_cd" {
  metadata {
    name = "argo-cd"
  }
  depends_on = [aws_eks_cluster.demo]
}

// helm chart for argocd, more here: https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd 

resource "helm_release" "argo-cd" {
  name = "argo-cd"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argo-cd"
  version    = "5.24.0"

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "argo-cd" // creates service account
  }

  depends_on = [aws_eks_cluster.demo]
}

*/