const Message = require("../models/Message");
const Chat = require("../models/Chat");
const Group = require("../models/Group");
const mongoose = require("mongoose");
const { generatePrivateChatId } = require("../utils/chatUtils");

const sendMessage = async (req, res) => {
    try {
        let { chatId, content, type, recipientId } = req.body;

        console.log(
            `📨 [SEND MESSAGE] User ${req.userId} sending message to chat ${chatId?.substring(0, 8)}...`,
        );

        if (!content) {
            console.log(`❌ [SEND MESSAGE] Missing content`);
            return res.status(400).json({ error: "content is required" });
        }

        let chat;

        // If recipientId is provided (private chat), find by members
        if (recipientId) {
            console.log(
                `🔄 [SEND MESSAGE] Private chat with recipient ${recipientId.substring(0, 8)}...`,
            );
            chat = await Chat.findOne({
                type: "private",
                members: { $all: [req.userId, recipientId] },
            });

            // Create if doesn't exist
            if (!chat) {
                console.log(`🆕 [SEND MESSAGE] Creating new private chat`);
                chat = new Chat({
                    type: "private",
                    members: [req.userId, recipientId],
                });
                await chat.save();
            }
        } else {
            // For group chats, use the provided chatId
            if (!chatId) {
                console.log(`❌ [SEND MESSAGE] Missing chatId for group chat`);
                return res
                    .status(400)
                    .json({ error: "chatId or recipientId is required" });
            }

            // Try to find Chat directly first
            chat = await Chat.findById(chatId);

            // If not found, it might be a Group ID
            if (!chat) {
                console.log(
                    `🔍 [SEND MESSAGE] Chat not found, checking if it's a Group ID: ${chatId}`,
                );
                const group = await Group.findById(chatId);

                if (group) {
                    console.log(`📦 [SEND MESSAGE] Found group: ${group.name}`);

                    // Get or create the chat for this group
                    if (group.chatId) {
                        chat = await Chat.findById(group.chatId);
                        console.log(
                            `💬 [SEND MESSAGE] Using existing group chat: ${group.chatId}`,
                        );
                    }

                    if (!chat) {
                        // Create chat for group
                        console.log(
                            `🆕 [SEND MESSAGE] Creating chat for group`,
                        );
                        chat = new Chat({
                            type: "group",
                            members: group.members,
                        });
                        await chat.save();

                        // Link chat to group
                        group.chatId = chat._id;
                        await group.save();
                        console.log(
                            `🔗 [SEND MESSAGE] Linked chat ${chat._id} to group ${group._id}`,
                        );
                    }
                } else {
                    console.log(
                        `❌ [SEND MESSAGE] Neither Chat nor Group found: ${chatId}`,
                    );
                    return res
                        .status(400)
                        .json({ error: "Chat or Group not found" });
                }
            }
        }

        // Create and save message
        const message = new Message({
            senderId: req.userId,
            chatId: chat._id,
            content,
            type: type || "text",
        });

        await message.save();
        console.log(
            `✅ [SEND MESSAGE] Message sent successfully - ID: ${message._id}`,
        );

        // Populate sender info
        await message.populate("senderId", "username");

        // Update chat's last message
        await Chat.findByIdAndUpdate(chat._id, {
            lastMessage: content,
            lastMessageTime: new Date(),
        });

        res.status(201).json(message);
    } catch (error) {
        console.error(`❌ [SEND MESSAGE ERROR] ${error.message}`);
        res.status(500).json({ error: error.message });
    }
};

const getPrivateMessages = async (req, res) => {
    try {
        const { userId1, userId2 } = req.params;
        const limit = parseInt(req.query.limit) || 20;
        const offset = parseInt(req.query.offset) || 0;

        console.log(
            `💬 [GET PRIVATE MESSAGES] Fetching private chat between ${userId1.substring(0, 8)}... and ${userId2.substring(0, 8)}... - Limit: ${limit}, Offset: ${offset}`,
        );

        // Validate user IDs
        if (!userId1 || !userId2 || userId1 === userId2) {
            console.log(`❌ [GET PRIVATE MESSAGES] Invalid user IDs`);
            return res.status(400).json({ error: "Invalid user IDs" });
        }

        // Find or create private chat between the two users (query by members)
        let chat = await Chat.findOne({
            type: "private",
            members: { $all: [userId1, userId2] },
        });

        let chatId = chat?._id;
        console.log(
            `🔍 [GET PRIVATE MESSAGES] Found existing chat: ${chat ? chat._id : "None"}`,
        );

        // If chat doesn't exist, create it
        if (!chat) {
            console.log(
                `🆕 [GET PRIVATE MESSAGES] Creating new private chat between users`,
            );
            chat = new Chat({
                type: "private",
                members: [userId1, userId2],
            });
            await chat.save();
            chatId = chat._id;
            console.log(
                `✅ [GET PRIVATE MESSAGES] Private chat created: ${chat._id}`,
            );
        }

        // Fetch messages from the chat
        const messages = await Message.find({ chatId })
            .populate("senderId", "username _id")
            .sort({ createdAt: -1 })
            .limit(limit)
            .skip(offset)
            .lean();

        console.log(
            `✅ [GET PRIVATE MESSAGES] Found ${messages.length} messages in chat ${chatId}`,
        );

        // Also check for any messages between these two users (for debugging)
        const allMessages = await Message.countDocuments({
            senderId: { $in: [userId1, userId2] },
        });
        console.log(
            `📊 [GET PRIVATE MESSAGES] Total messages from either user in DB: ${allMessages}`,
        );

        // Return messages in chronological order (oldest first)
        res.json(messages.reverse());
    } catch (error) {
        console.error(`❌ [GET PRIVATE MESSAGES ERROR] ${error.message}`);
        res.status(500).json({ error: error.message });
    }
};

const getGroupMessages = async (req, res) => {
    try {
        const { groupId } = req.params;
        const limit = parseInt(req.query.limit) || 20;
        const offset = parseInt(req.query.offset) || 0;

        console.log(
            `💬 [GET GROUP MESSAGES] Fetching group chat ${groupId} - Limit: ${limit}, Offset: ${offset}`,
        );

        let chatId = groupId;

        // Try to find Chat directly first
        let chat = await Chat.findById(groupId);

        // If not found, it might be a Group ID
        if (!chat) {
            console.log(
                `🔍 [GET GROUP MESSAGES] Chat not found, checking if it's a Group ID: ${groupId}`,
            );
            const group = await Group.findById(groupId);

            if (group) {
                console.log(
                    `📦 [GET GROUP MESSAGES] Found group: ${group.name}`,
                );

                // Get or create the chat for this group
                if (group.chatId) {
                    chat = await Chat.findById(group.chatId);
                    chatId = group.chatId.toString();
                    console.log(
                        `💬 [GET GROUP MESSAGES] Using existing group chat: ${chatId}`,
                    );
                }

                if (!chat) {
                    // Create chat for group
                    console.log(
                        `🆕 [GET GROUP MESSAGES] Creating chat for group`,
                    );
                    chat = new Chat({
                        type: "group",
                        members: group.members,
                    });
                    await chat.save();

                    // Link chat to group
                    group.chatId = chat._id;
                    await group.save();
                    chatId = chat._id.toString();
                    console.log(
                        `🔗 [GET GROUP MESSAGES] Linked chat ${chatId} to group ${group._id}`,
                    );
                }
            } else {
                console.log(
                    `❌ [GET GROUP MESSAGES] Neither Chat nor Group found: ${groupId}`,
                );
                return res
                    .status(404)
                    .json({ error: "Chat or Group not found" });
            }
        }

        const messages = await Message.find({ chatId: chatId })
            .populate("senderId", "username")
            .sort({ createdAt: -1 })
            .limit(limit)
            .skip(offset);

        console.log(
            `✅ [GET GROUP MESSAGES] Found ${messages.length} messages in chat ${chatId}`,
        );
        res.json(messages.reverse());
    } catch (error) {
        console.error(`❌ [GET GROUP MESSAGES ERROR] ${error.message}`);
        res.status(500).json({ error: error.message });
    }
};

const uploadFile = async (req, res) => {
    try {
        const { chatId } = req.params;
        console.log(
            `📎 [UPLOAD FILE] User ${req.userId} uploading file to chat ${chatId}`,
        );

        // For now, we'll simulate file upload by creating a message with type 'file'
        // In production, you'd use multer or similar to handle actual file uploads
        const { fileName, fileSize, fileType, content, message, recipientId } =
            req.body;

        let chat;

        // Handle both chatId and recipientId (for private chats)
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
            // Find or validate the chat by ID
            chat = await Chat.findById(chatId);
            if (!chat) {
                console.log(`❌ [UPLOAD FILE] Chat not found: ${chatId}`);
                return res.status(404).json({ error: "Chat not found" });
            }
        }

        // Check if user is a member of the chat
        const isMember = chat.members.some(
            (memberId) => memberId.toString() === req.userId.toString(),
        );
        if (!isMember) {
            console.log(`❌ [UPLOAD FILE] User not a member of chat`);
            console.log(`   User ID: ${req.userId}`);
            console.log(
                `   Chat members: ${chat.members.map((m) => m.toString()).join(", ")}`,
            );
            return res.status(403).json({
                error: "Not authorized to send messages in this chat",
            });
        }

        // Create message with file information
        const newMessage = new Message({
            senderId: req.userId,
            chatId: chat._id,
            content:
                message || content || `File: ${fileName || "uploaded-file"}`,
            type: "file",
            fileName: fileName || "uploaded-file",
            fileSize: fileSize || 0,
            fileType: fileType || "application/octet-stream",
        });

        await newMessage.save();
        console.log(
            `✅ [UPLOAD FILE] File message saved - ID: ${newMessage._id}`,
        );

        // Populate sender info
        await newMessage.populate("senderId", "username");

        // Update chat's last message
        await Chat.findByIdAndUpdate(chat._id, {
            lastMessage: `File: ${fileName || "uploaded-file"}`,
            lastMessageTime: new Date(),
        });

        res.status(201).json(newMessage);
    } catch (error) {
        console.error(`❌ [UPLOAD FILE ERROR] ${error.message}`);
        res.status(500).json({ error: error.message });
    }
};

module.exports = {
    sendMessage,
    getPrivateMessages,
    getGroupMessages,
    uploadFile,
};
