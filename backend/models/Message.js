const mongoose = require("mongoose");

const messageSchema = new mongoose.Schema(
    {
        senderId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
        },
        chatId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Chat",
            required: true,
        },
        content: {
            type: String,
            required: [true, "Message content is required"],
            maxlength: 5000,
        },
        type: {
            type: String,
            enum: ["text", "file"],
            default: "text",
        },
        fileUrl: {
            type: String,
            default: null,
        },
        fileName: {
            type: String,
            default: null,
        },
        fileSize: {
            type: Number,
            default: null,
        },
        fileType: {
            type: String,
            default: null,
        },
        readBy: [
            {
                userId: mongoose.Schema.Types.ObjectId,
                readAt: Date,
            },
        ],
    },
    {
        timestamps: true,
    },
);

// Index for faster queries
messageSchema.index({ chatId: 1, createdAt: -1 });

module.exports = mongoose.model("Message", messageSchema);
