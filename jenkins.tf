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

// creates persistent volume (no need already created by helm chart)



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




