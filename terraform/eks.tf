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
  cluster_upgrade_policy = {
    support_type = "STANDARD"
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