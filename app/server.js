const express = require("express");
const os = require("os");

const app = express();
const PORT = process.env.PORT || 3000;
const REGION = process.env.AWS_REGION_NAME || "local";

app.use(express.static(__dirname + "/public"));

// Used by ALB target group + Global Accelerator health checks
app.get("/health", (req, res) => res.status(200).json({ status: "ok" }));

// Shows which region/instance served the request
app.get("/api/info", (req, res) =>
  res.json({
    region: REGION,
    hostname: os.hostname(),
    uptimeSeconds: Math.round(process.uptime()),
    time: new Date().toISOString(),
  })
);

app.listen(PORT, "0.0.0.0", () => console.log(`Listening on ${PORT} (region=${REGION})`));
