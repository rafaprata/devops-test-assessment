output "configure_kubectl" {
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${data.aws_region.current.name}"
  description = "Command to configure kubeconfig"
}

output "ssh_to_bation" {
  value       = "ssh -i ${path.module}/../ssh_keys/id_rsa ec2-user@${module.ec2_instance.public_ip}"
  description = "Command to ssh into bastion"
}

output "ecr_repository" {
  value       = aws_ecr_repository.ecr.repository_url
  description = "URL to ECR repository"
}
