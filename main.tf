
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name                 = "eks-${var.cluster_name}-vpc"
  cidr                 = "172.16.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  public_subnets       = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/eks-${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/eks-${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.6"

  cluster_name    = "eks-${var.cluster_name}"
  cluster_version = "1.21"

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true
  cluster_security_group_tags = {

  }

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

    attach_cluster_primary_security_group = true

    # Disabling and using externally provided security groups
    create_security_group = false
    network_interfaces = [{
      delete_on_termination       = true
      associate_public_ip_address = true
    }]

  }

  eks_managed_node_groups = {
    complete = {
      name            = "nodegroup-1"
      use_name_prefix = true
      subnet_ids = module.vpc.private_subnets
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.small"]
      network_interfaces = [{
        delete_on_termination       = true
        associate_public_ip_address = true
      }]
      create_security_group          = true
      security_group_name            = "eks-managed-node-group-complete-example"
      security_group_use_name_prefix = false
      security_group_description     = "EKS managed node group complete example security group"
      security_group_tags = {
        Purpose = "Protector of the kubelet"
      }
    }
#    one = {
#      name = "node-group-1"
#
#      instance_types = ["t3.small"]
#
#      min_size     = 1
#      max_size     = 3
#      desired_size = 2
#
#      pre_bootstrap_user_data = <<-EOT
#      echo 'foo bar'
#      EOT
#
#      network_interfaces = [{
#        delete_on_termination       = true
#        associate_public_ip_address = true
#      }]
#    }
  }
}

#module "lb_role" {
#  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#
#  role_name = "dev_eks_lb"
#  attach_load_balancer_controller_policy = true
#
#  oidc_providers = {
#    main = {
#      provider_arn               = module.eks.oidc_provider_arn
#      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
#    }
#  }
#}
