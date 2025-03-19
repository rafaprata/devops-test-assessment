## IAM - Automated User
resource "aws_iam_user" "automated_user" {
  name = "user-${local.std_name}"
  path = "/"

  force_destroy = true
}

resource "aws_iam_access_key" "automated_user" {
  user = aws_iam_user.automated_user.name
}

resource "aws_iam_policy" "eks_user" {
  name = "eks-${local.std_name}"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "1",
        Effect   = "Allow",
        Action   = "eks:DescribeCluster",
        Resource = module.eks.cluster_arn
      },
      {
        Sid    = "GetAuthorizationToken",
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken"
        ],
        Resource = "*"
      },
      {
        Sid    = "ManageRepositoryContents",
        Effect = "Allow",
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ],
        Resource = aws_ecr_repository.ecr.arn
      }

    ]
  })
}

resource "aws_iam_user_policy_attachment" "policy_user" {
  user       = aws_iam_user.automated_user.name
  policy_arn = aws_iam_policy.eks_user.arn
}