const Message = require("../models/Message");
const Chat = require("../models/Chat");
const Group = require("../models/Group");
const mongoose = require("mongoose");
const { cloudinary } = require("../config/cloudinary");

const uploadFileToCloudinary = async (req, res) => {
    try {
        const { chatId } = req.params;
        console.log(
            `📎 [UPLOAD FILE CLOUDINARY] User ${req.userId} uploading file to chat ${chatId}`,
        );

        // Check if file was uploaded
        if (!req.file) {
            console.log(`❌ [UPLOAD FILE] No file uploaded`);
            return res.status(400).json({ error: "No file uploaded" });
        }

        const { recipientId, groupId } = req.body;
        let chat;

        // Handle both chatId and recipientId (for private chats) or groupId (for group chats)
        if (
            recipientId ||
            chatId === req.userId ||
            !mongoose.Types.ObjectId.isValid(chatId)
        ) {
            // This is a private chat request - find or create by members
            const otherUserId = recipientId || chatId;
            console.log(
                `🔍 [UPLOAD FILE] Finding private chat with user ${otherUserId}`,
            );

            chat = await Chat.findOne({
                type: "private",
                members: { $all: [req.userId, otherUserId] },
            });

            if (!chat) {
                console.log(`🆕 [UPLOAD FILE] Creating new private chat`);
                chat = new Chat({
                    type: "private",
                    members: [req.userId, otherUserId],
                });
                await chat.save();
            }
        } else {
            // Try to find Chat directly first
            chat = await Chat.findById(chatId);

            // If not found, it might be a Group ID
            if (!chat) {
                console.log(
                    `🔍 [UPLOAD FILE] Chat not found, checking if it's a Group ID: ${chatId}`,
                );
                const group = await Group.findById(chatId);

                if (group) {
                    console.log(`📦 [UPLOAD FILE] Found group: ${group.name}`);

                    // Get or create the chat for this group
                    if (group.chatId) {
                        chat = await Chat.findById(group.chatId);
                        console.log(
                            `💬 [UPLOAD FILE] Using existing group chat: ${group.chatId}`,
                        );
                    }

                    if (!chat) {
                        // Create chat for group
                        console.log(`🆕 [UPLOAD FILE] Creating chat for group`);
                        chat = new Chat({
                            type: "group",
                            members: group.members,
                        });
                        await chat.save();

                        // Link chat to group
                        group.chatId = chat._id;
                        await group.save();
                        console.log(
                            `🔗 [UPLOAD FILE] Linked chat ${chat._id} to group ${group._id}`,
                        );
                    }
                } else {
                    console.log(
                        `❌ [UPLOAD FILE] Neither Chat nor Group found: ${chatId}`,
                    );
                    return res.status(404).json({ error: "Chat not found" });
                }
            }
        }

        // Check if user is a member of the chat
        const isMember = chat.members.some(
            (memberId) => memberId.toString() === req.userId.toString(),
        );
        if (!isMember) {
            console.log(`❌ [UPLOAD FILE] User not a member of chat`);
            return res.status(403).json({
                error: "Not authorized to send messages in this chat",
            });
        }

        // File is already uploaded to Cloudinary by multer middleware
        const fileUrl = req.file.path; // Cloudinary URL
        const fileName = req.file.originalname;
        const fileSize = req.file.size;
        const fileType = req.file.mimetype;

        console.log(`☁️ [CLOUDINARY] File uploaded successfully`);
        console.log(`   URL: ${fileUrl}`);
        console.log(`   Name: ${fileName}`);
        console.log(`   Size: ${fileSize} bytes`);

        // Get caption from request body (optional)
        const caption = req.body.caption || "";
        console.log(`   Caption: ${caption || "(none)"}`);

        // Create message with file information
        const newMessage = new Message({
            senderId: req.userId,
            chatId: chat._id,
            content: caption || `File: ${fileName}`, // Use caption or default to filename
            type: "file",
            fileName,
            fileSize,
            fileType,
            fileUrl,
        });

        await newMessage.save();
        console.log(
            `✅ [UPLOAD FILE] File message saved - ID: ${newMessage._id}`,
        );

        // Populate sender info
        await newMessage.populate("senderId", "username");

        // Update chat's last message
        await Chat.findByIdAndUpdate(chat._id, {
            lastMessage: caption || `File: ${fileName}`,
            lastMessageTime: new Date(),
        });

        // 🔴 BROADCAST file message via socket to recipient
        const io = req.app.get("io");
        if (io) {
            const messageData = {
                _id: newMessage._id,
                senderId: newMessage.senderId._id,
                chatId: newMessage.chatId,
                content: newMessage.content,
                type: newMessage.type,
                fileName: newMessage.fileName,
                fileSize: newMessage.fileSize,
                fileType: newMessage.fileType,
                fileUrl: newMessage.fileUrl,
                createdAt: newMessage.createdAt,
                sender: {
                    _id: newMessage.senderId._id,
                    username: newMessage.senderId.username,
                },
            };
            const roomId = chat._id.toString();
            io.to(roomId).emit("receive_message", messageData);
            console.log(
                `📤 [FILE UPLOAD] Broadcasted to room ${roomId.substring(0, 8)}...`,
            );
        }

        res.status(201).json(newMessage);
    } catch (error) {
        console.error(`❌ [UPLOAD FILE ERROR] ${error.message}`);
        res.status(500).json({ error: error.message });
    }
};

module.exports = { uploadFileToCloudinary };
