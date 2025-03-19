### AWS Load Balancer Controller
module "aws_lb_controller" {
  source       = "github.com/rafaprata/terraform_modules/aws/aws_lb_controller"
  cluster_name = module.eks.cluster_name
  region       = data.aws_region.current.name
  # This value can be found at https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/latest
  aws_lb_controller_version = "v2.12.0"

  depends_on = [module.eks]
}