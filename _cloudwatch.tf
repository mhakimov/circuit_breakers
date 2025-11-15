resource "aws_cloudwatch_log_group" "yada" {
  name = "/ecs/circuit_breakers"

  tags = {
    Terraform = true
  }
}
