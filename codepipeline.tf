module aws_codepipeline {
  source = "./modules/aws_codepipeline"
  
  codebuild_project_name = var.codebuild_project_name

  github_token = var.github_token

  bucket_name = var.bucket_name

  pipeline_name = var.pipeline_name

  frontend_repo = var.frontend_repo

  git_email = var.git_email

  git_user = var.git_user

  git_repo = var.git_repo

  git_branch = "main"

}



