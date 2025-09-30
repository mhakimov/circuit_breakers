resource "aws_ecr_repository" "api_server_repo" {
  name                 = "api_server_repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
