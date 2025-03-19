# ### EC2 - Jumpbox
# resource "aws_key_pair" "ssh_key" {
#   key_name   = "key-${local.std_name}"
#   public_key = file("${path.module}/../ssh_keys/id_rsa.pub")
# }

# module "ec2_instance" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "~> 5.7.1"

#   name = "jumpbox-${local.std_name}-instance"

#   instance_type          = "t2.micro"
#   key_name               = aws_key_pair.ssh_key.key_name
#   vpc_security_group_ids = [aws_security_group.jumpbox_security_group.id, aws_security_group.internal_access_security_group.id, module.eks.cluster_security_group_id]
#   subnet_id              = module.vpc.public_subnets[0]

#   associate_public_ip_address = true

#   user_data = templatefile("${path.module}/templates/user_data.tftpl", {
#     k8s_version         = local.k8s_version
#     aws_region          = data.aws_region.current.name
#     aws_user_access_key = aws_iam_access_key.automated_user.id
#     aws_user_secret_key = aws_iam_access_key.automated_user.secret
#   })


#   depends_on = [module.eks]
# }

# resource "aws_security_group" "jumpbox_security_group" {
#   name   = "${local.std_name}-jumpbox-sg"
#   vpc_id = module.vpc.vpc_id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "TCP"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Allow SSH to the EC2"
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }