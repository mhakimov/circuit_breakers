locals {
  #   sfn_definition = jsonencode({
  #     Comment = "Circuit Breaker State Machine"
  #     StartAt = "CheckCircuit"
  #     States = {
  #       CheckCircuitState = {
  #         Type     = "Task"
  #         Resource = "arn:aws:states:::aws-sdk:dynamodb:getItem"
  #         Parameters = {
  #           TableName = aws_dynamodb_table.circuit_breaker.name
  #           Key = {
  #             serviceName = {
  #               "S" : "application-manager-api"
  #             }
  #           }
  #         },
  #         ResultPath = "$.circuit"
  #         Next       = "CircuitDecision"
  #       }

  #       CircuitDecision = {
  #         Type = "Choice"
  #         Choices = [
  #           {
  #             Variable     = "$.circuit.status"
  #             StringEquals = "OPEN"
  #             Next         = "CircuitOpen"
  #           }
  #         ]
  #         Default = "CallDownstream"
  #       }

  #       #   CircuitOpen = {
  #       #     Type = "Succeed"
  #       #   }

  #       #   CallDownstream = {
  #       #     Type     = "Task"
  #       #     Resource = var.call_service_lambda_arn
  #       #     Catch = [
  #       #       {
  #       #         ErrorEquals = ["States.ALL"]
  #       #         ResultPath  = "$.CallDownstream"
  #       #         Next        = "UpdateCircuit"
  #       #       }
  #       #     ]
  #       #     ResultPath = "$.CallDownstream"
  #       #     Next       = "UpdateCircuit"
  #       #   }

  #       #   UpdateCircuit = {
  #       #     Type       = "Task"
  #       #     Resource   = var.update_circuit_lambda_arn
  #       #     ResultPath = "$.UpdateCircuit"
  #       #     End        = true
  #       #   }
  #     }
  #   })


}

# resource "aws_sfn_state_machine" "circuit_breaker" {
#   name       = "Circuit Breaker"
#   role_arn   = aws_iam_role.sfn_role.arn
#   definition = local.sfn_definition
# }


# resource "aws_sfn_state_machine" "circuit_state_machine" {
#   name     = "Circuit Breaker"
#   role_arn = aws_iam_role.sfn_role.arn

#   definition = <<STATE_MACHINE
# {
#   "Comment": "Circuit-breaker flow: check DDB, call downstream Lambda, update CB state",
#   "StartAt": "GetCircuitState",
#   "States": {
#     "GetCircuitState": {
#       "Type": "Task",
#       "Resource": "arn:aws:states:::aws-sdk:dynamodb.getItem",
#       "Parameters": {
#         "TableName": "${aws_dynamodb_table.circuit_breaker.name}",
#         "Key": {
#           "serviceName": {
#             "S.$": "$.serviceName"
#           }
#         }
#       },
#       "ResultPath": "$.circuitItem",
#       "Catch": [
#         {
#           "ErrorEquals": ["States.ALL"],
#           "ResultPath": "$.getCircuitError",
#           "Next": "AssumeClosedOnDDBError"
#         }
#       ],
#       "Next": "DecideOnCircuitState"
#     }

#     "AssumeClosedOnDDBError": {
#       "Type": "Pass",
#       "Result": {
#         "Message": "DynamoDB GetItem failed - for safety assume CLOSED"
#       },
#       "Next": "DecideOnCircuitState"
#     },

#     "DecideOnCircuitState": {
#       "Type": "Choice",
#       "Choices": [
#         {
#           "Variable": "$.circuitItem.Item.status.S",
#           "StringEquals": "OPEN",
#           "Next": "CircuitOpen"
#         },
#         {
#           "Variable": "$.circuitItem.Item.status.S",
#           "StringEquals": "HALF_OPEN",
#           "Next": "InvokeDownstream"
#         },
#         {
#           "Variable": "$.circuitItem.Item.status.S",
#           "StringEquals": "CLOSED",
#           "Next": "InvokeDownstream"
#         }
#       ],
#       "Default": "InvokeDownstream"
#     },

#     "CircuitOpen": {
#       "Type": "Pass",
#       "Result": {
#         "status": "circuit_open"
#       },
#       "End": true
#     },

#     "InvokeDownstream": {
#       "Type": "Task",
#       "Resource": "arn:aws:states:::lambda:invoke",
#       "Parameters": {
#         "FunctionName": "${aws_lambda_function.processor.arn}",
#         # Pass the whole execution input (it must contain applicationId and serviceName)
#         "Payload.$": "$"
#       },
#       "ResultPath": "$.downstreamResult",
#       "Catch": [
#         {
#           "ErrorEquals": ["States.ALL"],
#           "ResultPath": "$.downstreamError",
#           "Next": "UpdateCircuitOnFailure"
#         }
#       ],
#       "Next": "UpdateCircuitOnSuccess"
#     },

#     "UpdateCircuitOnSuccess": {
#       "Type": "Task",
#       "Resource": "arn:aws:states:::lambda:invoke",
#       "Parameters": {
#         "FunctionName": "${var.update_circuit_lambda_arn}",
#         "Payload": {
#           "serviceName.$": "$.serviceName",
#           "applicationId.$": "$.applicationId",
#           "result": "SUCCESS",
#           "downstreamResult.$": "$.downstreamResult"
#         }
#       },
#       "ResultPath": "$.updateResult",
#       "Catch": [
#         {
#           "ErrorEquals": ["States.ALL"],
#           "ResultPath": "$.updateError",
#           "Next": "FinishWithUpdateError"
#         }
#       ],
#       "Next": "FinishSuccess"
#     },

#     "UpdateCircuitOnFailure": {
#       "Type": "Task",
#       "Resource": "arn:aws:states:::lambda:invoke",
#       "Parameters": {
#         "FunctionName": "${var.update_circuit_lambda_arn}",
#         "Payload": {
#           "serviceName.$": "$.serviceName",
#           "applicationId.$": "$.applicationId",
#           "result": "FAILURE",
#           "downstreamError.$": "$.downstreamError"
#         }
#       },
#       "ResultPath": "$.updateResultOnFailure",
#       "Catch": [
#         {
#           "ErrorEquals": ["States.ALL"],
#           "ResultPath": "$.updateError",
#           "Next": "FinishWithUpdateError"
#         }
#       ],
#       "Next": "FinishFailure"
#     },

#     "FinishSuccess": {
#       "Type": "Pass",
#       "Result": { "status": "ok" },
#       "End": true
#     },

#     "FinishFailure": {
#       "Type": "Pass",
#       "Result": { "status": "downstream_failed" },
#       "End": true
#     },

#     "FinishWithUpdateError": {
#       "Type": "Fail",
#       "Cause": "UpdateCircuitLambda failed",
#       "Error": "UpdateCircuitError"
#     }
#   }
# }
# STATE_MACHINE
# }


resource "aws_sfn_state_machine" "circuit_state_machine" {
  name     = "CircuitBreaker"
  role_arn = aws_iam_role.sfn_role.arn

  definition = <<STATE_MACHINE
{
  "Comment": "Circuit Breaker Workflow",
  "StartAt": "Get Circuit State",
  "States": {
    "Get Circuit State": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:dynamodb:getItem",
      "Parameters": {
        "TableName": "${aws_dynamodb_table.circuit_breaker.name}",
        "Key": {
          "ServiceName": {
            "S.$": "$.serviceName"
          }
        }
      },
      "ResultPath": "$.circuit",
      "Next": "Check Circuit Exists"
    },
    "Check Circuit Exists": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.circuit.Item",
          "IsPresent": true,
          "Next": "Check Circuit State"
        }
      ],
      "Default": "Assume Closed"
    },
    "Check Circuit State": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.circuit.Item.CircuitState.S",
          "StringEquals": "OPEN",
          "Next": "Check Cooldown"
        },
        {
          "Variable": "$.circuit.Item.CircuitState.S",
          "StringEquals": "CLOSED",
          "Next": "Call Downstream"
        },
        {
          "Variable": "$.circuit.Item.CircuitState.S",
          "StringEquals": "HALF_OPEN",
          "Next": "Call Downstream"
        }
      ],
      "Default": "Fail Invalid State"
    },
    "Assume Closed": {
      "Type": "Pass",
      "Result": {
        "assumedState": "CLOSED"
      },
      "Next": "Call Downstream"
    },
    "Check Cooldown": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.circuit.Item.LastStateChange.S",
          "IsPresent": true,
          "Next": "Evaluate Cooldown"
        }
      ],
      "Default": "Fail Invalid State"
    },


  }
}
STATE_MACHINE
}


# "Check Circuit Exists": {
#   "Type": "Choice",
#   "Choices": [
#     {
#       "Variable": "$.circuit.Item",
#       "IsPresent": true,
#       "Next": "Circuit Exists"
#     }
#   ],
#   "Default": "Assume Closed"
# },

# "Circuit Exists": {
#   "Type": "Succeed"
# },

# "Assume Closed": {
#   "Type": "Succeed"
# }
