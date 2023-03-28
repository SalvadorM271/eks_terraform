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
  
  codebuild_project_name = "codebuild-aws-pipeline"

  github_token = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["github_token"]

  bucket_name = "test-for-codepipeline-4736478364"

  pipeline_name = "mern-app-pipeline"

  frontend_repo = "153042419275.dkr.ecr.us-east-1.amazonaws.com/eks_mern_frontend" // change repo

  git_email = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_email"]

  git_user = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_user"]

  git_repo = "testmernapp"

  git_branch = "feature/new_feature" // change branch

  buildspec_file = "buildspec.yml" // change codebuild file name

}

// change name of module
module aws_codepipeline_develop {
  source = "./modules/aws_codepipeline"
  
  codebuild_project_name = "codebuild-aws-pipeline"

  github_token = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["github_token"]

  bucket_name = "test-for-codepipeline-4736478364"

  pipeline_name = "mern-app-pipeline"

  frontend_repo = "153042419275.dkr.ecr.us-east-1.amazonaws.com/eks_mern_frontend_dev" // change repo

  git_email = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_email"]

  git_user = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_user"]

  git_repo = "testmernapp"

  git_branch = "develop" // change branch

  buildspec_file = "buildspec-dev.yml" // change codebuild file name

}


// change name of module
module aws_codepipeline_main {
  source = "./modules/aws_codepipeline"
  
  codebuild_project_name = "codebuild-aws-pipeline"

  github_token = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["github_token"]

  bucket_name = "test-for-codepipeline-4736478364"

  pipeline_name = "mern-app-pipeline"

  frontend_repo = "153042419275.dkr.ecr.us-east-1.amazonaws.com/eks_mern_frontend_prod" // change repo

  git_email = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_email"]

  git_user = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_user"]

  git_repo = "testmernapp"

  git_branch = "main" // change branch

  buildspec_file = "buildspec-prod.yml" // change codebuild file name

}

// ------------------------------------------infra repo pipelines----------------------------------------------

module aws_codepipeline_feature_infra {
  source = "./modules/aws_codepipeline"
  
  codebuild_project_name = "codebuild-aws-pipeline-infra"

  github_token = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["github_token"]

  bucket_name = "test-for-codepipeline-4736478364-infra"

  pipeline_name = "mern-pipeline-infra"

  frontend_repo = "" // not needed for this, but only use to create env so can be blank

  git_email = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_email"]

  git_user = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_user"]

  git_repo = "eks_terraform" // change repo if needed

  git_branch = "feature/new_feature" // change branch

  buildspec_file = "buildspec.yml" // change codebuild file name

}


module aws_codepipeline_develop_infra {
  source = "./modules/aws_codepipeline"
  
  codebuild_project_name = "codebuild-aws-pipeline-infra"

  github_token = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["github_token"]

  bucket_name = "test-for-codepipeline-4736478364-infra"

  pipeline_name = "mern-pipeline-infra"

  frontend_repo = "" // not needed for this, but only use to create env so can be blank

  git_email = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_email"]

  git_user = jsondecode(data.aws_secretsmanager_secret_version.git-credentials.secret_string)["git_user"]

  git_repo = "eks_terraform" // change repo if needed

  git_branch = "develop" // change branch

  buildspec_file = "buildspec_dev.yml" // change codebuild file name

}

