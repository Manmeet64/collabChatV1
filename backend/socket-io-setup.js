const User = require("./models/User");
const Message = require("./models/Message");
const Chat = require("./models/Chat");
const Group = require("./models/Group");
const jwt = require("jsonwebtoken");
const { generatePrivateChatId } = require("./utils/chatUtils");

const setupSocketIO = (io) => {
    // Middleware for authentication
    io.use((socket, next) => {
        const token = socket.handshake.auth.token;

        if (!token) {
            return next(new Error("Authentication error"));
        }

        try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            socket.userId = decoded.userId;
            socket.username = decoded.username;
            next();
        } catch (err) {
            next(new Error("Authentication error"));
        }
    });

    // Connection
    io.on("connection", (socket) => {
        console.log(`✓ User connected: ${socket.username} (${socket.id})`);

        // Mark user as online
        User.findByIdAndUpdate(socket.userId, { isOnline: true }).exec();

        // Broadcast to all users
        const onlineUsersUpdate = async () => {
            const onlineUsers = await User.find({ isOnline: true }).select(
                "_id",
            );
            io.emit(
                "online_users",
                onlineUsers.map((u) => u._id.toString()),
            );
        };
        onlineUsersUpdate();

        // Join chat room
        socket.on("join", async ({ chatId, recipientId }) => {
            try {
                let actualChatId = chatId;
                let chat = null;

                // If recipientId provided, find or create the private chat
                if (recipientId) {
                    chat = await Chat.findOne({
                        type: "private",
                        members: { $all: [socket.userId, recipientId] },
                    });

                    // Create if doesn't exist
                    if (!chat) {
                        console.log(
                            `🆕 [WEBSOCKET JOIN] Creating new private chat`,
                        );
                        chat = new Chat({
                            type: "private",
                            members: [socket.userId, recipientId],
                        });
                        await chat.save();
                    }

                    actualChatId = chat._id.toString();
                    console.log(
                        `🔄 [WEBSOCKET JOIN] Resolved private chat ID: ${actualChatId.substring(0, 8)}...`,
                    );
                }

                socket.join(actualChatId);
                console.log(
                    `🚪 [WEBSOCKET] ${socket.username} joined chat ${actualChatId.substring(0, 8)}... (total in room: ${io.sockets.adapter.rooms.get(actualChatId)?.size || 1})`,
                );

                // Emit back the actual chat ID so frontend can update its state
                socket.emit("joined_chat", {
                    chatId: actualChatId,
                    recipientId: recipientId,
                });
            } catch (error) {
                console.error(`❌ [WEBSOCKET JOIN ERROR] ${error.message}`);
                socket.emit("error", { message: "Failed to join chat" });
            }
        });

        // Send message
        socket.on("send_message", async (data) => {
            try {
                let { chatId, message, type, recipientId } = data;
                console.log(
                    `📨 [WEBSOCKET] ${socket.username} sending message to chat ${chatId?.substring(0, 8)}...`,
                );

                if (!message) {
                    console.log(`❌ [WEBSOCKET] Missing message content`);
                    socket.emit("error", {
                        message: "Missing message content",
                    });
                    return;
                }

                let chat;

                // If recipientId is provided (private chat), find by members
                if (recipientId) {
                    console.log(
                        `🔄 [WEBSOCKET] Private chat with recipient ${recipientId.substring(0, 8)}...`,
                    );
                    chat = await Chat.findOne({
                        type: "private",
                        members: { $all: [socket.userId, recipientId] },
                    });

                    // Create if doesn't exist
                    if (!chat) {
                        console.log(`🆕 [WEBSOCKET] Creating new private chat`);
                        chat = new Chat({
                            type: "private",
                            members: [socket.userId, recipientId],
                        });
                        await chat.save();
                    }
                } else {
                    // For group chats, chatId might be a Group ID
                    if (!chatId) {
                        console.log(
                            `❌ [WEBSOCKET] Missing chatId for group chat`,
                        );
                        socket.emit("error", { message: "Missing chatId" });
                        return;
                    }

                    // Try to find Chat directly first
                    chat = await Chat.findById(chatId);

                    // If not found, it might be a Group ID
                    if (!chat) {
                        console.log(
                            `🔍 [WEBSOCKET] Chat not found, checking if it's a Group ID: ${chatId}`,
                        );
                        const group = await Group.findById(chatId);

                        if (group) {
                            console.log(
                                `📦 [WEBSOCKET] Found group: ${group.name}`,
                            );

                            // Get or create the chat for this group
                            if (group.chatId) {
                                chat = await Chat.findById(group.chatId);
                                console.log(
                                    `💬 [WEBSOCKET] Using existing group chat: ${group.chatId}`,
                                );
                            }

                            if (!chat) {
                                // Create chat for group
                                console.log(
                                    `🆕 [WEBSOCKET] Creating chat for group`,
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
                                    `🔗 [WEBSOCKET] Linked chat ${chat._id} to group ${group._id}`,
                                );
                            }
                        } else {
                            console.log(
                                `❌ [WEBSOCKET] Neither Chat nor Group found: ${chatId}`,
                            );
                            socket.emit("error", {
                                message: "Chat or Group not found",
                            });
                            return;
                        }
                    }
                }

                // 🔴 FIX: Ensure socket is joined to the room before sending
                const roomId = chat._id.toString();
                if (!socket.rooms.has(roomId)) {
                    socket.join(roomId);
                    console.log(
                        `🚪 [WEBSOCKET SEND] Joined room ${roomId.substring(0, 8)}... before sending message`,
                    );
                }

                // Save message to database
                const newMessage = new Message({
                    senderId: socket.userId,
                    chatId: chat._id,
                    content: message,
                    type: type || "text",
                });

                await newMessage.save();
                console.log(
                    `✅ [WEBSOCKET] Message saved successfully - ID: ${newMessage._id}`,
                );

                // Populate sender info
                await newMessage.populate("senderId", "username");

                // Update chat's last message
                await Chat.findByIdAndUpdate(chat._id, {
                    lastMessage: message,
                    lastMessageTime: new Date(),
                });

                // Broadcast to chat room
                const messageData = {
                    _id: newMessage._id,
                    senderId: newMessage.senderId._id,
                    chatId: newMessage.chatId,
                    content: newMessage.content,
                    type: newMessage.type,
                    createdAt: newMessage.createdAt,
                    sender: {
                        _id: newMessage.senderId._id,
                        username: newMessage.senderId.username,
                    },
                };

                const recipientCount =
                    io.sockets.adapter.rooms.get(roomId)?.size || 0;
                io.to(roomId).emit("receive_message", messageData);
                console.log(
                    `📤 [WEBSOCKET] Message broadcasted to room ${roomId.substring(0, 8)}... - Recipients: ${recipientCount}`,
                );
            } catch (error) {
                console.error(
                    `❌ [WEBSOCKET ERROR] Error sending message: ${error.message}`,
                );
                socket.emit("error", { message: "Failed to send message" });
            }
        });

        // Typing indicator
        socket.on("typing", ({ chatId, recipientId }) => {
            let actualChatId = chatId;

            // If using recipientId format, show recipient ID for logging
            if (recipientId) {
                console.log(
                    `⌨️  [WEBSOCKET] ${socket.username} is typing to ${recipientId.substring(0, 8)}...`,
                );
            } else {
                console.log(
                    `⌨️  [WEBSOCKET] ${socket.username} is typing in chat ${chatId.substring(0, 8)}...`,
                );
            }

            socket.to(actualChatId).emit("typing", {
                userId: socket.userId,
                username: socket.username,
            });
        });

        // Stop typing
        socket.on("stop_typing", ({ chatId, recipientId }) => {
            let actualChatId = chatId;

            if (recipientId) {
                console.log(
                    `🛑 [WEBSOCKET] ${socket.username} stopped typing to ${recipientId.substring(0, 8)}...`,
                );
            } else {
                console.log(
                    `🛑 [WEBSOCKET] ${socket.username} stopped typing in chat ${chatId.substring(0, 8)}...`,
                );
            }

            socket.to(actualChatId).emit("stop_typing", socket.userId);
        });

        // Disconnect
        socket.on("disconnect", async () => {
            console.log(
                `👋 [WEBSOCKET] ${socket.username} disconnected (${socket.id})`,
            );

            // Mark user as offline
            await User.findByIdAndUpdate(socket.userId, {
                isOnline: false,
                lastSeen: new Date(),
            });

            // Update online users
            const onlineUsers = await User.find({ isOnline: true }).select(
                "_id",
            );
            io.emit(
                "online_users",
                onlineUsers.map((u) => u._id.toString()),
            );
            console.log(
                `📊 [WEBSOCKET] Updated online users count: ${onlineUsers.length}`,
            );
        });
    });
};

module.exports = setupSocketIO;
