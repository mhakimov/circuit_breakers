resource "aws_iam_role" "sfn_role" {
  name = "circuit-state-machine-role"

  assume_role_policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Effect":"Allow",
      "Principal":{"Service":"states.amazonaws.com"},
      "Action":"sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "sfn_policy" {
  statement {
    sid = "DynamoDBGet"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:PutItem", # allow put for updater lambda's result writing through StepFunctions (if needed)
      "dynamodb:UpdateItem"
    ]
    resources = [
      aws_dynamodb_table.circuit_breaker.arn, # referenced below, or you can use arn:aws:dynamodb:*:*:table/${var.circuit_table_name}
      "${aws_dynamodb_table.circuit_breaker.arn}/*"
    ]
  }

  statement {
    sid = "InvokeLambdas"
    actions = [
      "lambda:InvokeFunction",
      "lambda:InvokeAsync"
    ]
    resources = [
      aws_lambda_function.processor.arn,
      #   var.update_circuit_lambda_arn
    ]
  }

  statement {
    sid = "Logs"
    actions = [
      "logs:CreateLogDelivery",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "sfn_inline_policy" {
  name   = "circuit-state-machine-policy"
  role   = aws_iam_role.sfn_role.id
  policy = data.aws_iam_policy_document.sfn_policy.json
}
