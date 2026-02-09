const mongoose = require("mongoose");

const groupSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: [true, "Group name is required"],
            minlength: 2,
            maxlength: 50,
        },
        description: {
            type: String,
            default: "",
            maxlength: 500,
        },
        members: [
            {
                type: mongoose.Schema.Types.ObjectId,
                ref: "User",
                required: true,
            },
        ],
        adminId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
        },
        chatId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Chat",
            default: null,
        },
        profilePicture: {
            type: String,
            default: null,
        },
    },
    {
        timestamps: true,
    },
);

module.exports = mongoose.model("Group", groupSchema);
