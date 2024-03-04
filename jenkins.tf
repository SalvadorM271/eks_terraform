// --------------------- comment this after creation so its not destroy on destroy run ---------------------------
// TODO add condition so its only created when dev env is created



// creates persistent volume (no need already created by helm chart)



// storage class (needed to connect efs to the pv and pvc created by the helm chart)

# WILL BE USING AN EC2 INSTEAD FOR JENKINS

# resource "kubernetes_storage_class" "efs_jenkins" {
#   metadata {
#     name = "efs-jenkins"
#   }
#   storage_provisioner = "efs.csi.aws.com"
#   parameters = {
#     provisioningMode = "efs-ap" # Add this line (change to "efs" if you prefer legacy mode)
#     fileSystemId     = aws_efs_file_system.efs_vol.id
#     directoryPerms   = "700"
#     gidRangeStart    = "1000"
#     gidRangeEnd      = "2000"
#     basePath         = "/var/jenkins_home"
#   }
# }


// creates persisten volume claim for kubernetes (no need already created by helm chart)



// deploy jenkins using helm, consider using this https://www.jenkins.io/projects/jcasc/ save config as yml

# resource "helm_release" "jenkins" {
#   name       = "jenkins"
#   repository = "https://charts.jenkins.io"
#   chart      = "jenkins"
#   namespace  = "default" 
#   version    = "4.3.20"

#   # values = [
#   #   "${file("./jenkins_values/values.yml")}"
#   # ]

#   set {
#     name  = "persistence.storageClass"
#     value = "efs-jenkins"
#   }

#   set {
#     name  = "controller.serviceType" // 9e6b29d-1600826435.us-east-1.elb.amazonaws.com:8080 remember port
#     value = "LoadBalancer"
#   }

#   set {
#     name  = "controller.service.port"
#     value = "8080"
#   }

#   set {
#     name  = "controller.service.targetPort"
#     value = "8080"
#   }

#   set_sensitive {
#     name  = "controller.adminUser"
#     value = var.jenkins_admin_user
#   }

#   set_sensitive {
#     name  = "controller.adminPassword"
#     value = var.jenkins_admin_password
#   }

#   // it is of most importance to configure jenkins tunnel to same url as jenkins url with diff port

#   set {
#     name  = "agent.enabled"
#     value = "true"
#   }

#   set {
#     name  = "agent.service.type"
#     value = "LoadBalancer"
#   }

#   set {
#     name  = "agent.service.port"
#     value = "50000"
#   }

#   set {
#     name  = "agent.service.targetPort"
#     value = "50000"
#   }



#   # set {
#   # name  = "agent.image"
#   # value = "crimson2022/test"
#   # }

#   # set {
#   #   name  = "agent.tag"
#   #   value = "2"
#   # }

# }




