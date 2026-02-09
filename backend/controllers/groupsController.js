const Group = require("../models/Group");
const Chat = require("../models/Chat");

const createGroup = async (req, res) => {
    try {
        const { name, members } = req.body;
        console.log(
            `📌 [CREATE GROUP] Creating group: ${name} with ${members.length} members`,
        );

        if (!name || !members || members.length === 0) {
            console.log(`❌ [CREATE GROUP] Missing name or members for group`);
            return res.status(400).json({ error: "Name and members required" });
        }

        // Add current user to members if not present
        if (!members.includes(req.userId)) {
            members.push(req.userId);
        }

        const group = new Group({
            name,
            members,
            adminId: req.userId,
        });

        await group.save();
        console.log(
            `✅ [CREATE GROUP] Group created successfully: ${name} (ID: ${group._id})`,
        );

        // Create group chat
        const chat = new Chat({
            type: "group",
            members: group.members,
        });

        await chat.save();
        console.log(
            `💬 [CREATE GROUP] Chat created for group: ${name} (Chat ID: ${chat._id})`,
        );

        // Link chat to group
        group.chatId = chat._id;
        await group.save();
        console.log(
            `🔗 [CREATE GROUP] Linked chat ${chat._id} to group ${group._id}`,
        );

        // Populate for response
        await group.populate([
            { path: "adminId", select: "username" },
            { path: "members", select: "username" },
        ]);

        res.status(201).json(group);
    } catch (error) {
        console.error(`❌ [CREATE GROUP ERROR] ${error.message}`);
        res.status(500).json({ error: error.message });
    }
};

const getMyGroups = async (req, res) => {
    try {
        console.log(
            `📋 [GET MY GROUPS] Fetching groups for user: ${req.userId}`,
        );
        const groups = await Group.find({ members: req.userId })
            .populate("adminId", "username")
            .populate("members", "username");

        console.log(
            `✅ [GET MY GROUPS] Found ${groups.length} groups for user`,
        );
        res.json(groups);
    } catch (error) {
        console.error(`❌ [GET MY GROUPS ERROR] ${error.message}`);
        res.status(500).json({ error: error.message });
    }
};

const addGroupMember = async (req, res) => {
    try {
        const { groupId } = req.params;
        const { userId } = req.body;
        console.log(
            `➕ [ADD GROUP MEMBER] Adding user ${userId} to group ${groupId}`,
        );

        const group = await Group.findById(groupId);

        if (!group) {
            console.log(`❌ [ADD GROUP MEMBER] Group not found: ${groupId}`);
            return res.status(404).json({ error: "Group not found" });
        }

        if (group.adminId.toString() !== req.userId) {
            console.log(
                `❌ [ADD GROUP MEMBER] Only admin can add members to group: ${groupId}`,
            );
            return res
                .status(403)
                .json({ error: "Only admin can add members" });
        }

        if (group.members.includes(userId)) {
            console.log(
                `❌ [ADD GROUP MEMBER] User ${userId} already in group ${groupId}`,
            );
            return res.status(400).json({ error: "User already in group" });
        }

        group.members.push(userId);
        await group.save();
        console.log(
            `✅ [ADD GROUP MEMBER] User ${userId} added to group ${groupId}`,
        );

        res.json({ success: true, message: "User added to group" });
    } catch (error) {
        console.error(`❌ [ADD GROUP MEMBER ERROR] ${error.message}`);
        res.status(500).json({ error: error.message });
    }
};

module.exports = { createGroup, getMyGroups, addGroupMember };
