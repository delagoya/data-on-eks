#################################################################################
# Required role and instance profile for EKS nodes used by AWS Batch
#   - AmazonEKSWorkerNodePolicy 
#   - AmazonEC2ContainerRegistryReadOnly
#   - AmazonEKS_CNI_Policy
################################################################################
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_instance_role" {
  name               = "eks_instance_role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}
resource "aws_iam_role_policy_attachment" "eks_instance_role_worker_policy" {
  role       = aws_iam_role.eks_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "eks_instance_role_ecr_policy" {
  role       = aws_iam_role.eks_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "eks_instance_role_cni_policy" {
  role       = aws_iam_role.eks_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_instance_profile" "eks_instance_profile" {
  name = "eks_instance_profile"
  role = aws_iam_role.eks_instance_role.name
}
