#################################################################################
# AWS Batch On-Demand EC2 compute environment
#################################################################################
resource "aws_batch_compute_environment" "eks_compute_env" {
  compute_environment_name = "eks-on-demand-ce"
  type         = "MANAGED"
  state        = "ENABLED"

  eks_configuration {
    eks_cluster_arn = module.eks.cluster_arn
    kubernetes_namespace = "aws-batch"
  }
  
  compute_resources {
    type = "EC2"
    allocation_strategy = "BEST_FIT_PROGRESSIVE"
    
    min_vcpus = var.aws_batch_min_vcpus
    max_vcpus = var.aws_batch_max_vcpus
    
    instance_type = var.aws_batch_instance_types
    instance_role = aws_iam_instance_profile.eks_instance_profile.arn

    security_group_ids = [
      module.eks.cluster_primary_security_group_id
    ]
    subnets = tolist(module.vpc.private_subnets)
  }

  depends_on = [
    kubernetes_namespace_v1.batch_namespace,
    kubernetes_role_binding_v1.batch_compute_env_role_binding,
    kubernetes_cluster_role_binding_v1.batch_cluster_role_binding,
    module.eks,
    module.eks_blueprints_addons
  ]
}

#################################################################################
# AWS Batch Job Queues
#################################################################################
resource "aws_batch_job_queue" "eks_job_queue" {
  name     = "eks-on-demand"
  state    = "ENABLED"
  priority = 1
  compute_environment_order {
    order = 1
    compute_environment = aws_batch_compute_environment.eks_compute_env.arn
  }
}


#################################################################################
# Batch Job Definition
#################################################################################
resource "aws_batch_job_definition" "eks_hello_world" {
  name = "sample-job-definition"
  type = "container"
  eks_properties {
    pod_properties {
      host_network = true
      containers {
        image = "public.ecr.aws/amazonlinux/amazonlinux:2023"
        command = [
          "echo",
          "'hello world!'"
        ]
        resources {
          limits = {
            cpu    = "1"
            memory = "1024Mi"
          }
        }
      }
      metadata {
        labels = {
          environment = "data-on-eks-sample"
        }
      }
    }
  }
}