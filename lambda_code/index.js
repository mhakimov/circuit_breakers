const https = require("https");
const http = require("http");

const apiBase = process.env.APPLICATION_MANAGER_API_SERVER;
// e.g. http://application-manager-api.appmgr-svc.local:3101/api

exports.handler = async (event) => {
    console.log("SQS event:", JSON.stringify(event, null, 2));

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

        // Choose http or https library
        const lib = url.protocol === "https:" ? https : http;

        // Configure request options
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
            timeout: 5000,
        };

        // Make the request
        await new Promise((resolve, reject) => {
            const req = lib.request(options, (res) => {
                let data = "";
                res.on("data", (chunk) => (data += chunk));
                res.on("end", () => {
                    console.log(`Response ${res.statusCode}: ${data}`);
                    if (res.statusCode >= 200 && res.statusCode < 300) resolve();
                    else reject(
                        new Error(`Failed with status ${res.statusCode}: ${data}`)
                    );
                });
            });

            req.on("error", (err) => {
                console.error("Request error:", err);
                reject(err);
            });

            req.write(payload);
            req.end();
        });
    }

    return { status: "ok" };
};
