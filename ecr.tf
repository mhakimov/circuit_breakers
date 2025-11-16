resource "aws_ecr_repository" "order_manager_repo" {
  name                 = "order_manager_repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
