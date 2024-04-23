variable "name" {
  description = "Name of the VPC and EKS Cluster"
  default     = "batch-eks"
  type        = string
}

variable "region" {
  description = "Region"
  default     = "us-east-2"
  type        = string
}

variable "eks_cluster_version" {
  description = "EKS Cluster version"
  type        = string
  default     = "1.29"
}

variable "tags" {
  description = "Default tags"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.1.0.0/16"
}

# Only two Subnets for with low IP range for internet access
variable "public_subnets" {
  description = "Public Subnets CIDRs. 62 IPs per Subnet"
  type        = list(string)
  default     = ["10.1.255.128/26", "10.1.255.192/26"]
}

variable "private_subnets" {
  description = "Private Subnets CIDRs. 32766 Subnet1 and 16382 Subnet2 IPs per Subnet"
  type        = list(string)
  default     = ["10.1.0.0/17", "10.1.128.0/18"]
}

variable "eks_public_cluster_endpoint" {
  description = "Whether to have a public or private cluster endpoint for the EKS cluster"
  type = bool
  default = true
}

variable "aws_batch_min_vcpus" {
  description = "The minumum aggregate vCPU for AWS Batch compute environment"
  type = number
  default = 0
}
  
variable "aws_batch_max_vcpus" {
  description = "The minumum aggregate vCPU for AWS Batch compute environment"
  type = number
  default = 256
}

variable "aws_batch_instance_types" {
  description = "The set of instance types to launch for jobs"
  type = list(string)
  default = [ "c5","m5","r5" ]
}