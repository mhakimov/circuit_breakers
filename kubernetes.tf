data "aws_eks_cluster_auth" "demo" {
  name = aws_eks_cluster.demo.name
}

resource "kubernetes_namespace" "demo" {
  metadata {
    name = "demo"
  }
}

resource "kubernetes_deployment" "flaky_api" {
  metadata {
    name      = "flaky-api"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "flaky-api"
      }
    }
    template {
      metadata {
        labels = {
          app = "flaky-api"
        }
      }
      spec {
        container {
          name  = "api"
          image = "${aws_ecr_repository.api_server_repo.repository_url}:latest"
          port {
            container_port = 5000
          }

          resources {
            limits = {
              cpu    = "512m"
              memory = "1Gi"
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

resource "kubernetes_service" "flaky_api_svc" {
  metadata {
    name      = "flaky-api-svc"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }
  spec {
    selector = {
      app = "flaky-api"
    }
    port {
      port        = 80
      target_port = 5000
    }
    type = "LoadBalancer"
  }
}
