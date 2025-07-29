
locals {
  node_role_arn   = aws_iam_role.eks_nodes.arn
  worker_node_policy = aws_iam_role_policy_attachment.eks_nodes_AmazonEKSWorkerNodePolicy
}

#managed node group
resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-ng"
  node_role_arn   = local.node_role_arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_eks_cluster.main,
    local.worker_node_policy,
    aws_iam_role_policy_attachment.eks_nodes_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_nodes_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = { Name = "${var.cluster_name}-ng" }
}

#oidc provider (irsa)
resource "aws_iam_openid_connect_provider" "main" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0afd10df6"]
}


#irsa roles - externaldns + certmanager
module "external_dns_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.2"

  role_name                  = "external-dns"
  attach_external_dns_policy = true
  external_dns_hosted_zone_arns = [
    "arn:aws:route53:::hostedzone/Z03548873UFVKFZA5D7IP"
  ]

  oidc_providers = {
    this = {
      provider_arn               = aws_iam_openid_connect_provider.main.arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }
}

module "cert_manager_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.2"

  role_name                  = "cert-manager-new"
  attach_cert_manager_policy = true

  oidc_providers = {
    this = {
      provider_arn               = aws_iam_openid_connect_provider.main.arn
      namespace_service_accounts = ["cert-manager:cert-manager"]
    }
  }
}




#eks cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = "1.30"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy]

  tags = { Name = var.cluster_name }
}

#iam - node group
data "aws_iam_policy_document" "eks_nodes_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
     identifiers = ["ec2.amazonaws.com", "eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_nodes" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_nodes_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


# iam - control plane
data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}