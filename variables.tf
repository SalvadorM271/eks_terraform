// -----------------aws codepipeline module----------------

//variable codebuild_project_name {}

//variable github_token {}

//variable bucket_name {}

//variable pipeline_name {}

//variable frontend_repo {}

//variable git_email {}

//variable git_user {}

//variable git_repo {}

variable region {
    default = "us-east-1"
}

variable project_name {
    default = "eks-test-cluster"
}

variable environment {
    default = "dev"
}

variable vpc_cidr {
    default = "10.0.0.0/16"
}

variable private_subnet1_cidr {
    default = "10.0.0.0/19"
}

variable private_subnet2_cidr {
    default = "10.0.32.0/19"
}

variable public_subnet1_cidr {
    default = "10.0.64.0/19"
}

variable public_subnet2_cidr {
    default = "10.0.96.0/19"
}

variable node_group_instance {
    default = "t3.small"
}

variable node_group_desire_size {
    default = "4"
}

variable node_group_max_size {
    default = "10"
}

variable node_group_min_size {
    default = "0"
}

variable rds_instance {
    default = "db.t2.micro"
}

variable rds_storage_type {
    default = "gp2"
}

