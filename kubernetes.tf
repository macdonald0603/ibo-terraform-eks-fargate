# Configure the Kubernetes provider to interact with your EKS cluster
provider "kubernetes" {
  host                   = aws_eks_cluster.ibo_prod_eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.ibo_prod_eks.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.ibo_prod_eks.token
}

resource "kubernetes_deployment" "ibo_app" {
  metadata {
    name      = "ibo-prod-newdocker"
    namespace = "default"
    labels = {
      app = "ibo-prod-newdocker"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "ibo-prod-newdocker"
      }
    }

    template {
      metadata {
        labels = {
          app = "ibo-prod-newdocker"
        }
      }

      spec {
        container {
          name  = "ibo-prod-newdocker"
          image = "920373000297.dkr.ecr.us-east-2.amazonaws.com/ibo-prod-newdocker:latest"
          
          port {
            container_port = 80
            protocol       = "TCP"
          }

          resources {
            limits = {
              cpu    = "256m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "256m"
              memory = "512Mi"
            }
          }
        }
      }
    }
  }
}
