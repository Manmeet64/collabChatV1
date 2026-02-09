const Message = require("../models/Message");
const Chat = require("../models/Chat");
const Group = require("../models/Group");

/**
 * Migration endpoint to populate chatId for existing groups
 */
const migrateGroupChatIds = async (req, res) => {
    try {
        console.log(
            `🔄 [MIGRATE] Starting migration to populate chatId for groups...`,
        );

        // Find all groups without chatId
        const groupsWithoutChatId = await Group.find({
            $or: [{ chatId: null }, { chatId: { $exists: false } }],
        });

        console.log(
            `🔄 [MIGRATE] Found ${groupsWithoutChatId.length} groups without chatId`,
        );

        let updated = 0;
        let errors = 0;

        for (const group of groupsWithoutChatId) {
            try {
                // Find chat with same members and type 'group'
                const chat = await Chat.findOne({
                    type: "group",
                    members: {
                        $all: group.members,
                        $size: group.members.length,
                    },
                });

                if (chat) {
                    group.chatId = chat._id;
                    await group.save();
                    console.log(
                        `✅ [MIGRATE] Updated group ${group._id} with chatId ${chat._id}`,
                    );
                    updated++;
                } else {
                    // Create new chat if not found
                    const newChat = new Chat({
                        members: group.members,
                        type: "group",
                    });
                    await newChat.save();

                    group.chatId = newChat._id;
                    await group.save();
                    console.log(
                        `✅ [MIGRATE] Created chat ${newChat._id} for group ${group._id}`,
                    );
                    updated++;
                }
            } catch (err) {
                console.error(
                    `❌ [MIGRATE] Error processing group ${group._id}: ${err.message}`,
                );
                errors++;
            }
        }

        console.log(
            `✅ [MIGRATE] Migration complete: ${updated} updated, ${errors} errors`,
        );

        res.json({
            success: true,
            message: "Migration complete",
            stats: {
                total: groupsWithoutChatId.length,
                updated,
                errors,
            },
        });
    } catch (error) {
        console.error(`❌ [MIGRATE ERROR] ${error.message}`);
        res.status(500).json({ error: error.message });
    }
};

/**
 * Debug endpoint to find all chats and messages between two users
 */
const debugChatHistory = async (req, res) => {
    try {
        const { userId1, userId2 } = req.params;

        console.log(`🔍 [DEBUG] Searching for all chats between users...`);

        // Find all chats with these users
        const allChats = await Chat.find({
            members: { $all: [userId1, userId2] },
        }).lean();

        console.log(
            `🔍 [DEBUG] Found ${allChats.length} chat(s) with both users`,
        );

        const result = {
            users: [userId1, userId2],
            chats: [],
        };

        for (const chat of allChats) {
            const messages = await Message.find({ chatId: chat._id }).lean();
            result.chats.push({
                chatId: chat._id,
                type: chat.type,
                members: chat.members,
                messageCount: messages.length,
                lastMessage: messages[messages.length - 1] || null,
            });
            console.log(`  Chat ${chat._id}: ${messages.length} messages`);
        }

        // Also check for messages directly between these users
        const directMessages = await Message.find({
            senderId: { $in: [userId1, userId2] },
        }).lean();

        console.log(
            `🔍 [DEBUG] Found ${directMessages.length} total messages from either user`,
        );

        result.totalDirectMessages = directMessages.length;

        res.json(result);
    } catch (error) {
        console.error(`❌ [DEBUG ERROR] ${error.message}`);
        res.status(500).json({ error: error.message });
    }
};

module.exports = { debugChatHistory, migrateGroupChatIds };
