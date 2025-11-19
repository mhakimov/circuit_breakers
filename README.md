{
  "applicationId": "12345",
  "decision": "approve",
  "source": "test-seed-data"
}



WO CB:
- queue will grow
- lambda will get charged
- callee will not have chance to recover



DynamoDB Table

Create a table, e.g., CircuitBreaker, with:

PK: serviceName (string)

status: "CLOSED" | "OPEN" | "HALF_OPEN" (string)

failureCount: number

lastFailureTime: timestamp (number)