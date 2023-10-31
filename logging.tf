# resource "kubernetes_namespace" "prometheus-stack" {
#   metadata {
#     name = "prometheus-stack"
#   }
# }

# this helm chart does not have permissions in its cluster role to use the alb controller and external dns controller if they are deploy in another namespace

resource "helm_release" "kube-prometheus-stack-chart" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "51.10.0"

  # namespace = kubernetes_namespace.prometheus-stack.metadata[0].name
  namespace = "default"

  # this custom values from line 928 to line 968 were modify so grafana creates an ingress so the service is expose by an alb

  values = [file("./helm_custom_values/kube-prometheus-stack/values.yaml")] #error ingressClass, external dns, secrets needed bf hand

  # since after creating the ingress for grafana its service remains of type clusterIp, and the load balancer controller requires type NodePort the following was required

  set {
    name = "grafana.service.type"
    value = "NodePort"
  }

  # you can check the generated ingress with kubectl get ingress createdIngressName -n prometheus-stack -oyaml
  # to get the ingress name use kubectl get ingress -n prometheus-stack

  depends_on = [aws_eks_node_group.private-nodes]

}