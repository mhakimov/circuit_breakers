# resource "aws_lambda_function" "sqs_consumer" {
#   function_name = "sqs-consumer"
#   role          = aws_iam_role.lambda_exec.arn
#   runtime       = "python3.11"
#   handler       = "lambda_function.handler"

#   filename         = "${path.module}/lambda_code/lambda.zip"
#   source_code_hash = filebase64sha256("${path.module}/lambda_code/lambda.zip")

#   environment {
#     variables = {
#       API_URL = kubernetes_service.unstable_api.status[0].load_balancer[0].ingress[0].hostname
#     }
#   }
# }

# resource "aws_iam_role" "lambda_exec" {
#   name = "lambdaExecRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Action    = "sts:AssumeRole"
#       Effect    = "Allow"
#       Principal = { Service = "lambda.amazonaws.com" }
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
#   role       = aws_iam_role.lambda_exec.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
#   event_source_arn = aws_sqs_queue.requests.arn
#   function_name    = aws_lambda_function.sqs_consumer.arn
# }
