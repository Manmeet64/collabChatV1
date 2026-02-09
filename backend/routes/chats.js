const express = require("express");
const authMiddleware = require("../middleware/auth");
const {
    sendMessage,
    getPrivateMessages,
    getGroupMessages,
    uploadFile,
} = require("../controllers/chatsController");
const {
    uploadFileToCloudinary,
} = require("../controllers/fileUploadController");
const { upload } = require("../config/cloudinary");

const router = express.Router();

router.post("/send", authMiddleware, sendMessage);
router.get("/private/:userId1/:userId2", authMiddleware, getPrivateMessages);
router.get("/group/:groupId", authMiddleware, getGroupMessages);

// File upload endpoints
router.post("/private/:chatId/messages", authMiddleware, uploadFile); // Metadata only (current)
router.post("/group/:chatId/messages", authMiddleware, uploadFile); // Metadata only (current)
router.post(
    "/upload/:chatId",
    authMiddleware,
    upload.single("file"),
    uploadFileToCloudinary,
); // Actual file upload with Cloudinary

module.exports = router;
