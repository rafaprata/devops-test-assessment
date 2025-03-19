data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_region" "current" {}

locals {
  std_name    = "heartcentrix-assesment"
  vpc_cidr    = "10.0.0.0/16"
  azs         = slice(data.aws_availability_zones.available.names, 0, 2)
  k8s_version = "1.31"
}

### VPC 
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "vpc-${local.std_name}"
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 2)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_security_group" "internal_access_security_group" {
  name   = "${local.std_name}-internal-access-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.vpc_cidr]
    description = "Allow internal access"
  }
}

resource "aws_security_group" "jumpbox_security_group" {
  name   = "${local.std_name}-jumpbox-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH to the EC2"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

### EKS
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "eks-${local.std_name}"
  cluster_version = local.k8s_version

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_additional_security_group_ids = [aws_security_group.internal_access_security_group.id]

  cluster_endpoint_public_access = true

  self_managed_node_groups = {
    main = {
      ami_type      = "AL2023_x86_64_STANDARD"
      instance_type = "t3.large"
      min_size      = 0
      max_size      = 5
      desired_size  = 2

      cloudinit_pre_nodeadm = [
        {
          content_type = "application/node.eks.aws"
          content      = <<-EOT
            ---
            apiVersion: node.eks.aws/v1alpha1
            kind: NodeConfig
            spec:
              kubelet:
                config:
                  shutdownGracePeriod: 30s
                  featureGates:
                    DisableKubeletCloudCredentialProviders: true
          EOT
        }
      ]
    }
  }

  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  cluster_upgrade_policy = {
    support_type = "STANDARD"
  }

  access_entries = {
    automated_user = {
      kubernetes_groups = []
      principal_arn     = aws_iam_user.automated_user.arn

      policy_associations = {
        admin_view = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"
          access_scope = {
            namespaces = []
            type       = "cluster"
          }
        }
        edit = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
          access_scope = {
            namespaces = ["default"]
            type       = "namespace"
          }
        }
      }

    }

  }
}

resource "aws_ecr_repository" "ecr" {
  name                 = "hello-api"
  image_tag_mutability = "IMMUTABLE"

  force_delete = true
}

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
         Sid = "GetAuthorizationToken",
         Effect = "Allow",
         Action = [
            "ecr:GetAuthorizationToken"
         ],
         Resource = "*"
      },
      {
         Sid = "ManageRepositoryContents",
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

### EC2 - Jumpbox
resource "aws_key_pair" "ssh_key" {
  key_name   = "key-${local.std_name}"
  public_key = file("${path.module}/../ssh_keys/id_rsa.pub")
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  name = "jumpbox-${local.std_name}-instance"

  instance_type          = "t2.micro"
  key_name               = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.jumpbox_security_group.id, aws_security_group.internal_access_security_group.id, module.eks.cluster_security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  associate_public_ip_address = true

  user_data = templatefile("${path.module}/templates/user_data.tftpl", {
    k8s_version         = local.k8s_version
    aws_region          = data.aws_region.current.name
    aws_user_access_key = aws_iam_access_key.automated_user.id
    aws_user_secret_key = aws_iam_access_key.automated_user.secret
  })


  depends_on = [module.eks]
}

### AWS Load Balancer Controller

module "aws_lb_controller" {
  source       = "github.com/rafaprata/terraform_modules/aws/aws_lb_controller"
  cluster_name = module.eks.cluster_name
  region       = data.aws_region.current.name
  # This value can be found at https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/latest
  aws_lb_controller_version = "v2.12.0"

  depends_on = [module.eks]
}