const express = require("express");
const authMiddleware = require("../middleware/auth");
const {
    debugChatHistory,
    migrateGroupChatIds,
} = require("../controllers/debugController");

const router = express.Router();

// Debug endpoints - only in development mode
if (process.env.NODE_ENV === "development") {
    router.get("/chats/:userId1/:userId2", authMiddleware, debugChatHistory);
    router.post("/migrate-group-chatids", authMiddleware, migrateGroupChatIds);
}

module.exports = router;
