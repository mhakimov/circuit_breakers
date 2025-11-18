resource "aws_dynamodb_table" "circuit_breaker" {
  name         = "CircuitBreaker"
  billing_mode = "PAY_PER_REQUEST" # No capacity planning required
  hash_key     = "serviceName"

  attribute {
    name = "serviceName"
    type = "S"
  }

  #   tags = {
  #     Name = "CircuitBreaker"
  #     App  = "application-manager"
  #   }
}

resource "aws_iam_policy" "circuit_breaker_access" {
  name        = "circuit-breaker-dynamodb-access"
  description = "Allows Lambda to read/write circuit breaker state"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem"
        ]
        Resource = aws_dynamodb_table.circuit_breaker.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_circuit_breaker_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.circuit_breaker_access.arn
}
