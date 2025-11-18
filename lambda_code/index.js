const https = require("https");
const http = require("http");
const AWS = require("aws-sdk");

const dynamodb = new AWS.DynamoDB.DocumentClient();
const circuitTable = process.env.CIRCUIT_TABLE || "CircuitBreaker";
const FAILURE_THRESHOLD = process.env.FAILURE_THRESHOLD || 3;
const OPEN_TIMEOUT_MS = 30000; // 30 seconds
const serviceName = "application-manager-api"; // unique per service


const apiBase = process.env.APPLICATION_MANAGER_API_SERVER;
// e.g. http://application-manager-api.appmgr-svc.local:3101/api

async function makeRequest(url, payload) {
    const lib = url.protocol === "https:" ? https : http;
    const options = {
        hostname: url.hostname,
        port: url.port,
        path: url.pathname + url.search,
        method: "PUT",
        headers: {
            "Content-Type": "application/json",
            "Content-Length": Buffer.byteLength(payload),
            "x-tfsuserid": "lambda-user",
        },
        timeout: 20000,
    };

    return new Promise((resolve, reject) => {
        const req = lib.request(options, (res) => {
            let data = "";
            res.on("data", (chunk) => (data += chunk));
            res.on("end", () => {
                console.log(`Response ${res.statusCode}: ${data}`);
                if (res.statusCode >= 200 && res.statusCode < 300) resolve();
                else reject(new Error(`Failed with status ${res.statusCode}: ${data}`));
            });
        });

        req.on("timeout", () => {
            console.error("Request timed out");
            // Causes "error" event to fire with this error
            req.destroy(new Error("Request timed out"));
        });
        req.on("error", (err) => {
            console.error("Request error:", err);
            reject(err);
        });
        req.write(payload);
        req.end();
    });
}

async function getCircuitState() {
    const res = await dynamodb
        .get({ TableName: circuitTable, Key: { serviceName } })
        .promise();
    if (!res.Item) {
        return { status: "CLOSED", failureCount: 0, lastFailureTime: 0 };
    }
    const { status, failureCount, lastFailureTime } = res.Item;

    if (status === "OPEN" && Date.now() - lastFailureTime > OPEN_TIMEOUT_MS) {
        // Move to half-open
        return { status: "HALF_OPEN", failureCount, lastFailureTime };
    }

    return { status, failureCount, lastFailureTime };
}

async function updateCircuitState(newState) {
    await dynamodb
        .put({
            TableName: circuitTable,
            Item: { serviceName, ...newState },
        })
        .promise();
}

exports.handler = async (event) => {
    console.log("SQS event:", JSON.stringify(event, null, 2));

    const circuit = await getCircuitState();
    console.log("Circuit state:", circuit);

    if (circuit.status === "OPEN") {
        console.warn("Circuit is OPEN, skipping requests");
        return { status: "circuit_is_open" };
    }

    for (const record of event.Records) {
        const body = JSON.parse(record.body);
        const applicationId = body.applicationId || body.id;
        if (!applicationId) {
            console.warn("Missing applicationId in message:", record.body);
            continue;
        }

        // Compose request URL
        const url = new URL(`${apiBase}/applications/${applicationId}/decision`);

        // Request payload
        const payload = JSON.stringify({ decision: "approve" });

        try {
            await makeRequest(url, payload);

            // Success → reset circuit if half-open or increment success in closed
            await updateCircuitState({ status: "CLOSED", failureCount: 0, lastFailureTime: 0 });
            console.log(`Successfully processed application ${applicationId}`);
        } catch (err) {
            console.error("Request failed:", err);

            let failureCount = (circuit.failureCount || 0) + 1;
            let newState = { failureCount, lastFailureTime: Date.now(), status: "CLOSED" };

            if (failureCount >= FAILURE_THRESHOLD) {
                newState.status = "OPEN";
                console.warn(`Circuit opened due to ${failureCount} failures`);
            } else if (circuit.status === "HALF_OPEN") {
                newState.status = "OPEN";
                console.warn(`Circuit reverted to OPEN from HALF_OPEN`);
            }
            await updateCircuitState(newState);

        }
    }

    return { status: "ok" };
};
