## to use the kubernetes provider in eks cluster this must be configure

## creates a file with what is needed to use kubernetes in our cluster

data "aws_eks_cluster_auth" "cluster_kube_config" {
  name = aws_eks_cluster.demo.id // this one needs to change for multi env since it uses cluster as ref
  depends_on = [aws_eks_cluster.demo]
}

provider "kubernetes" {
  host                   = aws_eks_cluster.demo.endpoint
  token                  = data.aws_eks_cluster_auth.cluster_kube_config.token
  cluster_ca_certificate = base64decode(aws_eks_cluster.demo.certificate_authority.0.data)
}




