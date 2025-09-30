# provider "kubernetes" {
#   host                   = aws_eks_cluster.demo.endpoint
#   cluster_ca_certificate = base64decode(aws_eks_cluster.demo.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.demo.token
# }

# data "aws_eks_cluster_auth" "demo" {
#   name = aws_eks_cluster.demo.name
# }

# resource "kubernetes_deployment" "unstable_api" {
#   metadata {
#     name      = "unstable-api"
#     namespace = "default"
#     labels = {
#       app = "unstable-api"
#     }
#   }

#   spec {
#     replicas = 2
#     selector {
#       match_labels = {
#         app = "unstable-api"
#       }
#     }
#     template {
#       metadata {
#         labels = {
#           app = "unstable-api"
#         }
#       }
#       spec {
#         container {
#           name  = "unstable-api"
#           image = "public.ecr.aws/docker/library/python:3.11-slim" # Simple Python container
#           port {
#             container_port = 8080
#           }
#           command = [
#             "python", "-m", "http.server", "8080"
#           ]
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_service" "unstable_api" {
#   metadata {
#     name = "unstable-api"
#   }

#   spec {
#     selector = {
#       app = kubernetes_deployment.unstable_api.metadata[0].labels.app
#     }
#     port {
#       port        = 80
#       target_port = 8080
#     }
#     type = "LoadBalancer"
#   }
# }
