// --------------------- comment this after creation so its not destroy on destroy run ---------------------------
// TODO add condition so its only created when dev env is created

// creates security group for jenkins and efs to comunicate

resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "EFS Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 2049 # NFS (Network File System) port
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  tags = {
    Name = "efs-sg"
  }
}

// create local to avoid repetition of mount code

locals {
  subnet_ids = [
    aws_subnet.private-us-east-1a.id,
    aws_subnet.private-us-east-1b.id,
  ]
}

resource "aws_efs_mount_target" "jenkins" {
  count           = length(local.subnet_ids) // result of count is 2 so two resources are created
  file_system_id  = aws_efs_file_system.jenkins.id
  subnet_id       = local.subnet_ids[count.index] // loops through every subnet
  security_groups = [aws_security_group.efs_sg.id] 
}

// creates persistent volume (kubernetes provider already define in kubernetes.tf)

resource "kubernetes_persistent_volume" "jenkins" {
  metadata {
    name = "jenkins-efs-pv"
  }
  spec {
    capacity = {
      storage = "10Gi" # Adjust the storage capacity as needed
    }
    access_modes = ["ReadWriteMany"] # Allows multiple pods to read and write concurrently
    persistent_volume_reclaim_policy = "Retain" # Retains the volume data when the PVC is deleted
    storage_class_name = "efs-jenkins"
    persistent_volume_source {
      csi {
        driver = "efs.csi.aws.com"
        volume_handle = aws_efs_file_system.jenkins.id // the efs volume i created
        volume_attributes = {
          "path" = "/var/jenkins_home" # The path of the exported EFS volume
        }
      }
    }
  }
}

// storage class

resource "kubernetes_storage_class" "efs_jenkins" {
  metadata {
    name = "efs-jenkins"
  }
  storage_provisioner = "efs.csi.aws.com"
  parameters = {
    provisioningMode = "efs-ap" # Add this line (change to "efs" if you prefer legacy mode)
    fileSystemId     = aws_efs_file_system.jenkins.id
    directoryPerms   = "700"
    gidRangeStart    = "1000"
    gidRangeEnd      = "2000"
    basePath         = "/var/jenkins_home"
  }
}


// creates persisten volume claim for kubernetes

resource "kubernetes_persistent_volume_claim" "jenkins" {
  metadata {
    name      = "jenkins-efs-pvc"
    namespace = "default" # if this change you need to create the namespace
  }
  spec {
    access_modes = ["ReadWriteMany"] # Allows multiple pods to read and write concurrently
    resources {
      requests = {
        storage = "10Gi" # Adjust the storage request as needed
      }
    }
    volume_name = kubernetes_persistent_volume.jenkins.metadata[0].name
  }
  timeouts {
    create = "10m" # Increase this value as needed
  }
  depends_on = [aws_eks_cluster.demo]
}

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




