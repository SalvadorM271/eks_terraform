// ----------- no need to create a new rol for now since external dns already had a rol -----------


/* this is use in order to retrive secrets from asw secrets manager to our eks cluster
(the provider for helm was define in the loadbalancer_controller.tf)*/

/*data "aws_iam_policy_document" "aws_csi_driver_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" // to make it better pass var for namespace
      values   = ["system:serviceaccount:default:secret-store-csi-driver"] // put your service acc name here and namespace wher it lives
      //rol is restricted to only be use by the service account define above by sub, check eks notes
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}*/

/*i think this rol goes directly on the deployment that uses secrets
https://www.youtube.com/watch?app=desktop&v=Rmgo6vCytsg&ab_channel=AntonPutra 
minute 13:55
in the same video minute 5:47 explains that you need to create a service account for your deployment
(in his case an ngnix deployment) and assosiate this rol to it using an annotation*/

/*resource "aws_iam_role" "aws_csi_driver_rol" {
  //the policy define with data is like a template for easy use we pass it here to create the policy
  assume_role_policy = data.aws_iam_policy_document.aws_csi_driver_assume_role_policy.json
  name               = "aws-csi-driver"
}

resource "aws_iam_policy" "eks_csi_driver_policy" {
  name        = "eks-deployment-policy"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        // you need to specify the arn of the secret you want to use in the app if you need
        // more than one you can use a comma and if you need them all you can use
        // arn:aws:secretsmanager:*:*:secret:*(not tested)
        Resource = ["arn:aws:secretsmanager:us-east-1:153042419275:secret:cloudflare-ZlOXvE"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_csi_driver_attach" {
  role       = aws_iam_role.aws_csi_driver_rol.name
  policy_arn = aws_iam_policy.eks_csi_driver_policy.arn
}*/

// no need to adjust this for mult env deployment since it will be deploy on proper cluster thx to state

resource "helm_release" "secrets-store-csi-driver" {
  name       = "csi-secrets-store"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = "1.2.4"

  namespace = "kube-system"
  // you can see opt values here https://secrets-store-csi-driver.sigs.k8s.io/getting-started/installation.html#installation
  set {
    name  = "enableSecretRotation"
    value = "true"
  }

  set {
    name  = "syncSecret.enabled"
    value = "true"
  }

  depends_on = [aws_eks_node_group.private-nodes]
  
  //this dont show on the documentation but aparently you can add them to any helm release
}

// no need to adjust this for mult env deployment since it will be deploy on proper cluster thx to state

resource "helm_release" "secrets-store-csi-driver-provider-aws" {
  name       = "secrets-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  version    = "0.1.0"

  namespace = "kube-system"

  set {
    name  = "region"
    value = "us-east-1"
  }

  depends_on = [aws_eks_node_group.private-nodes]

}
