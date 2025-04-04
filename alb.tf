# Data resource to fetch AWS account ID (if necessary)
data "aws_caller_identity" "current" {}

# Declare or import the EKS cluster if it already exists
resource "aws_eks_cluster" "ibo_prod" {
  name    = "ibo-prod-eks-cluster"
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/eks-cluster-role"
  vpc_config {
    subnet_ids = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  }
}

# Create the Application Load Balancer
resource "aws_lb" "public_alb" {
  name               = "ibo-prod-public-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]
  security_groups    = [aws_security_group.ibo_prod_app_web_sg.id]
}

# Create Target Group for the ALB
resource "aws_lb_target_group" "ibo_target_group" {
  name        = "ibo-prod-app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ibo_prod_app.id
  target_type = "ip"  # Needed for EKS workloads

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }
}

# Create Listener for HTTP on the ALB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ibo_target_group.arn
  }
}

# Create IAM Role for ALB Ingress Controller
resource "aws_iam_role" "alb_ingress_role" {
  name = "aws-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/oidc.eks.${var.aws_region}.amazonaws.com/id/${aws_eks_cluster.ibo_prod.identity[0].oidc[0].issuer}"
        }
        Condition = {
          StringEquals = {
            "oidc.eks.${var.aws_region}.amazonaws.com/id/${aws_eks_cluster.ibo_prod.identity[0].oidc[0].issuer}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

# Create Service Account for ALB Ingress Controller
resource "kubernetes_service_account" "alb_ingress_service_account" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
  }

  automount_service_account_token = true
}

# Create Kubernetes Role Binding for ALB Ingress Controller
resource "kubernetes_role_binding" "alb_ingress_role_binding" {
  metadata {
    name      = "aws-load-balancer-controller-role-binding"
    namespace = "kube-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "aws-load-balancer-controller"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.alb_ingress_service_account.metadata[0].name
    namespace = "kube-system"
  }
}

# Install the AWS Load Balancer Controller using Helm
resource "helm_release" "alb_ingress_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "2.5.1"  # Replace with the desired version

  set {
    name  = "clusterName"
    value = aws_eks_cluster.ibo_prod.name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.alb_ingress_service_account.metadata[0].name
  }

  depends_on = [kubernetes_service_account.alb_ingress_service_account]
}

# Output the ALB DNS Name
output "alb_dns_name" {
  value       = aws_lb.public_alb.dns_name
  description = "The DNS name of the ALB"
}

# Route 53 record points to domain of the ALB
resource "aws_route53_record" "alb_record" {
  zone_id = "C0535728H8WC95RU7CDT"  # Replace with your hosted zone ID
  name    = "independentbooksonline.com"  # The domain name
  type    = "A"  # Type A record (for IPv4)
  ttl     = 300  # Time to live (in seconds)
  records = [aws_lb.public_alb.dns_name]  # ALB DNS name as the record value
}
