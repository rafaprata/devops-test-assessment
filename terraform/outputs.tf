resource "local_file" "outputs" {
  content = templatefile(
    "${path.module}/templates/outputs.tftpl",
    {
      aws_user_id       = aws_iam_access_key.automated_user.id
      aws_user_secret   = aws_iam_access_key.automated_user.secret
      cluster_name      = module.eks.cluster_name
      aws_region        = data.aws_region.current.name
      bastion_public_ip = module.ec2_instance.public_ip
      path              = path.module
      aws_ecr_url       = aws_ecr_repository.ecr.repository_url
    }
  )
  filename = "${path.module}/../outputs/outputs.md"

}
