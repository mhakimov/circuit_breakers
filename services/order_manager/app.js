import express from "express";
const app = express();

app.use(express.json());

// Health check endpoint
app.get("/health", (req, res) => {
    res.status(200).send("ok");
});

// Endpoint Lambda will call
app.put("/api/applications/:applicationId/decision", (req, res) => {
    console.log("Received decision for application:", req.params.applicationId);
    console.log("Request body:", req.body);

    // Simulate simple logic
    res.status(200).json({
        applicationId: req.params.applicationId,
        status: "decision accepted",
        decision: req.body.decision || "unknown"
    });
});

const PORT = process.env.PORT || 3101;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Application Manager API running on port ${PORT}`);
});
