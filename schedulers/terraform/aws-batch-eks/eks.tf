################################################################################
# Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.21"

  cluster_name                   = local.name
  cluster_version                = var.eks_cluster_version
  cluster_endpoint_public_access = local.eks_public_cluster_endpoint

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Fargate profiles use the cluster primary security group so these are not utilized
  create_cluster_security_group = false
  create_node_security_group    = false

  manage_aws_auth_configmap = true
  aws_auth_roles = [
    # Map AWS Batch service-linked role with the user referenced in the roles below.
    # Add instance profile for the AWS Batch nodes
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWSServiceRoleForBatch"
      username = "aws-batch"
      groups   = []
    },
    {
      rolearn  = aws_iam_role.eks_instance_role.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ]

  fargate_profiles = {
    kube_system = {
      name = "kube-system"
      selectors = [
        { namespace = "kube-system" }
      ]
    }
  }

  tags = local.tags
}

################################################################################
# EKS Blueprints Addons
################################################################################

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.14"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # We want to wait for the Fargate profiles to be deployed first
  create_delay_dependencies = [for prof in module.eks.fargate_profiles : prof.fargate_profile_arn]

  eks_addons = {
    coredns = {
      configuration_values = jsonencode({
        computeType = "Fargate"
        # Ensure that the we fully utilize the minimum amount of resources that are supplied by
        # Fargate https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html
        # Fargate adds 256 MB to each pod's memory reservation for the required Kubernetes
        # components (kubelet, kube-proxy, and containerd). Fargate rounds up to the following
        # compute configuration that most closely matches the sum of vCPU and memory requests in
        # order to ensure pods always have the resources that they need to run.
        resources = {
          limits = {
            cpu = "0.25"
            # We are targeting the smallest Task size of 512Mb, so we subtract 256Mb from the
            # request/limit to ensure we can fit within that task
            memory = "256M"
          }
          requests = {
            cpu = "0.25"
            # We are targeting the smallest Task size of 512Mb, so we subtract 256Mb from the
            # request/limit to ensure we can fit within that task
            memory = "256M"
          }
        }
      })
    }
    vpc-cni    = {}
    kube-proxy = {}
  }

  tags = local.tags
}

################################################################################
# K8s resources to enable AWS Batch
################################################################################

resource "kubernetes_namespace_v1" "batch_namespace" {
  metadata {
    annotations = {
      name = "aws-batch"
    }

    labels = {
      name = "aws-batch"
    }

    name = "aws-batch"
  }
}

resource "kubernetes_cluster_role_v1" "batch_cluster_role" {
  metadata {
    name = "aws-batch-cluster-role"
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get"]
  }
  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups  = [""]
    resources  = ["configmaps"]
    verbs      =["get", "list", "watch"]
  }
  rule {
    api_groups  = ["apps"]
    resources  = ["daemonsets", "deployments", "statefulsets", "replicasets"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["clusterroles", "clusterrolebindings"]
    verbs      = ["get", "list"]
  } 
}

resource "kubernetes_cluster_role_binding_v1" "batch_cluster_role_binding" {
  metadata {
    name = "aws-batch-cluster-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name = kubernetes_cluster_role_v1.batch_cluster_role.metadata[0].name
  }
  subject {
    kind      = "User"
    name      = "aws-batch"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_role_v1" "batch_compute_env_role" {
  metadata {
    name = "aws-batch-compute-environment-role"
    namespace = kubernetes_namespace_v1.batch_namespace.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["create", "get", "list", "watch", "delete", "patch"]
  }
  rule {
    api_groups = [""]
    resources  = ["serviceaccounts"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["roles", "rolebindings"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_role_binding_v1" "batch_compute_env_role_binding" {
  metadata {
    name = "aws-batch-compute-environment-role-binding"
    namespace = kubernetes_namespace_v1.batch_namespace.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name = kubernetes_role_v1.batch_compute_env_role.metadata[0].name
  }
  subject {
    kind      = "User"
    name      = "aws-batch"
    api_group = "rbac.authorization.k8s.io"
  }
}
