// s3 bucket

resource "aws_s3_bucket" "artifact_store" {
  bucket = "${var.bucket_name}-${substr(var.git_branch, 0, 7)}" // substr is use in all intances bc of the _
  acl    = "private"
}

// codepipeline rol

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.pipeline_name}-rol-${substr(var.git_branch, 0, 7)}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.codepipeline_role.name
}

// codepipeline

/*after terraform code is run, the pipeline will fail since the CodeStar Connection you made isn’t available
to finish the creation of the pipeline you need to go to your pipeline, then settings, connections, 
then select the connection with status pending, Then select “Update pending connection”
Another screen will pop up. Select “Install a new app”, Next, click on your GitHub account and then select
the repository, or repositories you want the AWS Connector to have access to.(im selecting the app and
infra repo at this time), Click “save”, Next you will come back to the “Connect to GitHub” screen. Hit “Connect”
if everything went well it should display status available in the connection, this needs to be done one
time per pipeline*/

resource "aws_codestarconnections_connection" "github_codepipeline" {
  name          = "${substr(var.git_branch, 0, 7)}-${var.pipeline_name}-con"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "this" {
  name     = "${var.pipeline_name}-${substr(var.git_branch, 0, 7)}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact_store.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn = aws_codestarconnections_connection.github_codepipeline.arn
        FullRepositoryId = "${var.git_user}/${var.git_repo}"
        BranchName = var.git_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.this.name
      }
    }
  }

  stage {
    name = "Manual_Approval"
    action {
      name     = "Manual-Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

}


// codebuild rol

resource "aws_iam_role" "codebuild_role" {
  name = "${var.codebuild_project_name}-rol-${substr(var.git_branch, 0, 7)}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.codebuild_role.name
}

// codebuild

resource "aws_codebuild_project" "this" {
  name          = "${var.codebuild_project_name}-${substr(var.git_branch, 0, 7)}"
  description   = "My CodeBuild project for building and pushing Docker images"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:3.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "FRONTEND"
      value = var.frontend_repo
    }

    environment_variable {
      name  = "GIT_USER_EMAIL"
      value = var.git_email
    }

    environment_variable {
      name  = "GIT_USER_NAME"
      value = var.git_user
    }

    environment_variable {
      name  = "GITHUB_TOKEN"
      value = var.github_token
    }

    environment_variable {
      name  = "REPO_NAME"
      value = var.git_repo
    }
    # Add other environment variables if necessary
  }

  source {
    type            = "CODEPIPELINE"
    buildspec       = var.buildspec_file
    git_clone_depth = 1
  }

  
}