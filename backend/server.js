const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const mongoose = require("mongoose");
const { createServer } = require("http");
const { Server: SocketIOServer } = require("socket.io");
const setupSocketIO = require("./socket-io-setup");

// Load environment variables
dotenv.config();

const app = express();

const httpServer = createServer(app);
const io = new SocketIOServer(httpServer, {
    cors: {
        origin:
            process.env.NODE_ENV === "development"
                ? true
                : process.env.CORS_ORIGIN?.split(",") || "*",
        methods: ["GET", "POST"],
        credentials: true,
    },
});

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
    console.log(`📡 [REQUEST] ${req.method} ${req.path}`);
    next();
});

// CORS Configuration
const corsOptions = {
    origin: (origin, callback) => {
        // Allow all localhost origins in development
        if (process.env.NODE_ENV === "development") {
            callback(null, true);
        } else {
            // In production, use specific origins from .env
            const allowed = process.env.CORS_ORIGIN?.split(",") || [];
            if (allowed.includes(origin) || !origin) {
                callback(null, true);
            } else {
                callback(new Error("CORS not allowed"));
            }
        }
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
};

app.use(cors(corsOptions));

// MongoDB Connection
mongoose
    .connect(process.env.MONGODB_URI)
    .then(() => console.log("✓ MongoDB connected"))
    .catch((err) => console.error("MongoDB connection error:", err));

// Attach io instance to app for access in controllers
app.set("io", io);

// Routes
app.use("/api/v1/auth", require("./routes/auth"));
app.use("/api/v1/users", require("./routes/users"));
app.use("/api/v1/groups", require("./routes/groups"));
app.use("/api/v1/chats", require("./routes/chats"));
app.use("/api/v1/debug", require("./routes/debug"));

// Health Check
app.get("/health", (req, res) => {
    res.json({ status: "OK", timestamp: new Date() });
});

// 404 Handler
app.use((req, res) => {
    res.status(404).json({ error: "Not Found" });
});

// Error Handling Middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(err.status || 500).json({
        error: err.message || "Internal Server Error",
        status: err.status || 500,
    });
});

// Setup WebSocket
setupSocketIO(io);

// Start Server
const PORT = process.env.PORT || 3001;
httpServer.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
    console.log(`📊 Environment: ${process.env.NODE_ENV}`);
});

module.exports = { app, io, httpServer };
