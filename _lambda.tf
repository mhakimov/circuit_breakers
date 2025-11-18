data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_code"
  output_path = "${path.module}/lambda_code.zip"
}


resource "aws_lambda_function" "processor" {
  function_name                  = "${var.project}-processor"
  role                           = aws_iam_role.lambda_exec.arn
  handler                        = "index.handler"
  runtime                        = "nodejs18.x"
  filename                       = data.archive_file.lambda_zip.output_path
  source_code_hash               = data.archive_file.lambda_zip.output_base64sha256
  reserved_concurrent_executions = 1

  memory_size = 512
  timeout     = 30

  vpc_config {
    # subnet_ids         = values(aws_subnet.private)[*].id
    subnet_ids         = module.network.private_subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      APPLICATION_MANAGER_API_SERVER = "http://application-manager-api.${aws_service_discovery_private_dns_namespace.ns.name}:3101/api"
      SQS_QUEUE_URL                  = aws_sqs_queue.queue.id
      FAILURE_THRESHOLD              = 3
      CIRCUIT_TABLE                  = aws_dynamodb_table.circuit_breaker.name
    }
  }
}


resource "aws_security_group" "lambda_sg" {
  name   = "${var.project}-lambda-sg"
  vpc_id = module.network.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Allow lambda to reach ecs tasks: (security group reference)
# resource "aws_security_group_rule" "lambda_to_ecs" {
#   type              = "egress"
#   from_port         = 3101
#   to_port           = 3101
#   protocol          = "tcp"
#   security_group_id = aws_security_group.lambda_sg.id
#   destination_security_group_id = aws_security_group.ecs_sg.id
# }

# resource "aws_vpc_security_group_egress_rule" "lambda_to_ecs" {
#   security_group_id = aws_security_group.lambda_sg.id

#   #   cidr_ipv4   = "10.0.0.0/8"
#   from_port                    = 3101
#   ip_protocol                  = "tcp"
#   to_port                      = 3101
#   referenced_security_group_id = aws_security_group.ecs_sg.id
# }


# Event source mapping
resource "aws_lambda_event_source_mapping" "sqs_map" {
  event_source_arn = aws_sqs_queue.queue.arn
  function_name    = aws_lambda_function.processor.arn
  batch_size       = 1
  enabled          = true
}
