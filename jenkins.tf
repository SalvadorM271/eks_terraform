// --------------------- comment this after creation so its not destroy on destroy run ---------------------------
// TODO add condition so its only created when dev env is created



// creates persistent volume (no need already created by helm chart)



// storage class

resource "kubernetes_storage_class" "efs_jenkins" {
  metadata {
    name = "efs-jenkins"
  }
  storage_provisioner = "efs.csi.aws.com"
  parameters = {
    provisioningMode = "efs-ap" # Add this line (change to "efs" if you prefer legacy mode)
    fileSystemId     = aws_efs_file_system.efs_vol.id
    directoryPerms   = "700"
    gidRangeStart    = "1000"
    gidRangeEnd      = "2000"
    basePath         = "/var/jenkins_home"
  }
}


// creates persisten volume claim for kubernetes (no need already created by helm chart)



// deploy jenkins using helm, consider using this https://www.jenkins.io/projects/jcasc/ save config as yml

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  namespace  = "default" 
  version    = "4.3.20"

  # values = [
  #   "${file("./jenkins_values/values.yml")}"
  # ]

  set {
    name  = "persistence.storageClass"
    value = "efs-jenkins"
  }

  # set_sensitive {
  #   name  = "controller.adminUser"
  #   value = var.jenkins_admin_user
  # }

  # set_sensitive {
  #   name  = "controller.adminPassword"
  #   value = var.jenkins_admin_password
  # }

}




