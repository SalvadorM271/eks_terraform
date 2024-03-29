/*SO HERE IM CREATING ALL THE PIPELINES I NEED IN ONE GO, i dont need to create more when i create
the other two enviroments, so im gonna put a restriction so it only creates them when i create
the dev enviroment*/
/*
// ----------------------------------------------credentials-----------------------------------------------

// i decided to put this here and not inside the module to make this as modular as possible

data "aws_secretsmanager_secret" "git-credentials" {
  name = "git-personal-credentials"
}

data "aws_secretsmanager_secret_version" "git-credentials" {
  secret_id = data.aws_secretsmanager_secret.git-credentials.id
}

// DONT USE BRANCHES WITH UNDERSCORE (i use a temp fix that can be seen in the module)

// ------------------------------------------app repo pipelines-----------------------------------------------

// change name of module
module aws_codepipeline_feature {
  source = "./modules/aws_codepipeline"

  count = var.environment == "dev" ? 1 : 0 // if not dev create 0 instances of this resource/module
  
  codebuild_project_name = "codebuild-aws-pipeline"

  github_token = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["github_token"]

  bucket_name = "test-for-codepipeline-4736478364"

  pipeline_name = "mern-app-pipeline"

  frontend_repo = "153042419275.dkr.ecr.us-east-1.amazonaws.com/eks_mern_frontend" // change repo

  git_email = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_email"]

  git_user = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_user"]

  docker_user = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["docker_user"]

  docker_password = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["docker_password"]

  git_repo = "testmernapp"

  git_branch = "feature/new_feature" // change branch

  buildspec_file = "buildspec.yml" // change codebuild file name

}

// change name of module
module aws_codepipeline_develop {
  source = "./modules/aws_codepipeline"

  count = var.environment == "dev" ? 1 : 0 // if not dev create 0 instances of this resource/module
  
  codebuild_project_name = "codebuild-aws-pipeline"

  github_token = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["github_token"]

  bucket_name = "test-for-codepipeline-4736478364"

  pipeline_name = "mern-app-pipeline"

  frontend_repo = "153042419275.dkr.ecr.us-east-1.amazonaws.com/eks_mern_frontend_dev" // change repo

  git_email = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_email"]

  git_user = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_user"]

  docker_user = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["docker_user"]

  docker_password = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["docker_password"]

  git_repo = "testmernapp"

  git_branch = "develop" // change branch

  buildspec_file = "buildspec-dev.yml" // change codebuild file name

}

module aws_codepipeline_stg {
  source = "./modules/aws_codepipeline"

  count = var.environment == "dev" ? 1 : 0 // if not dev create 0 instances of this resource/module
  
  codebuild_project_name = "codebuild-aws-pipeline"

  github_token = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["github_token"]

  bucket_name = "test-for-codepipeline-4736478364"

  pipeline_name = "mern-app-pipeline"

  frontend_repo = "153042419275.dkr.ecr.us-east-1.amazonaws.com/eks_mern_frontend_staging" // change repo

  git_email = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_email"]

  git_user = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_user"]

  docker_user = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["docker_user"]

  docker_password = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["docker_password"]

  git_repo = "testmernapp"

  git_branch = "staging" // change branch

  buildspec_file = "buildspec-stg.yml" // change codebuild file name

}


// change name of module
module aws_codepipeline_main {
  source = "./modules/aws_codepipeline"

  count = var.environment == "dev" ? 1 : 0 // if not dev create 0 instances of this resource/module
  
  codebuild_project_name = "codebuild-aws-pipeline"

  github_token = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["github_token"]

  bucket_name = "test-for-codepipeline-4736478364"

  pipeline_name = "mern-app-pipeline"

  frontend_repo = "153042419275.dkr.ecr.us-east-1.amazonaws.com/eks_mern_frontend_prod" // change repo

  git_email = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_email"]

  git_user = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_user"]

  docker_user = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["docker_user"]

  docker_password = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["docker_password"]

  git_repo = "testmernapp"

  git_branch = "main" // change branch

  buildspec_file = "buildspec-prod.yml" // change codebuild file name

}

// ------------------------------------------infra repo pipelines----------------------------------------------

// aws codepipelien does not take wild cards so feature/* branch needs to be pull manually

module aws_codepipeline_main_infra {
  source = "./modules/aws_codepipeline"

  count = var.environment == "dev" ? 1 : 0 // if not dev create 0 instances of this resource/module
  
  codebuild_project_name = "codebuild-aws-pipeline-infra"

  github_token = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["github_token"]

  bucket_name = "test-for-codepipeline-4736478364-infra"

  pipeline_name = "mern-pipeline-infra"

  frontend_repo = "" // not needed for this, only use to create env so can be blank (creates blank env)

  git_email = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_email"]

  git_user = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_user"]

  git_repo = "eks_terraform" // change repo if needed

  git_branch = "main" // change branch

  buildspec_file = "buildspec_main.yml" // change codebuild file name

}

*/

