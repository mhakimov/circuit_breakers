import express from "express";
const app = express();
app.use(express.json());

// Health check endpoint
app.get("/health", (req, res) => {
    res.status(200).send("ok");
});

// Random delay/failure simulator
app.put("/api/applications/:applicationId/decision", async (req, res) => {
    const { applicationId } = req.params;
    const decision = req.body.decision || "unknown";

    const FAILURE_RATE = process.env.FAILURE_RATE || 0.3;
    const TIMEOUT_RATE = process.env.FAILURE_RATE || 0.5;


    console.log(`Incoming decision request for ${applicationId}`);

    // Random artificial latency (0–10 seconds)
    const delay = Math.floor(Math.random() * 10000);
    await new Promise(resolve => setTimeout(resolve, delay));

    // Random failure simulation
    const random = Math.random();
    if (random < FAILURE_RATE) {
        console.log("Simulating server error (500)");
        return res.status(500).json({ error: "Internal Server Error" });
    }
    if (random < TIMEOUT_RATE) {
        console.log("Simulating timeout (no response)");
        // Never send a response so that connection will hang until Lambda times out
        return;
    }

    // Normal success
    console.log("Responding successfully");
    res.status(200).json({
        applicationId,
        status: "decision accepted",
        decision,
        delayMs: delay
    });
});

const PORT = process.env.PORT || 3101;
app.listen(PORT, "0.0.0.0", () => {
    console.log(`Unreliable Application Manager API running on port ${PORT}`);
});
