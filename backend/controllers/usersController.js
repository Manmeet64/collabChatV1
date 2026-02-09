const User = require("../models/User");

const getCurrentUser = async (req, res) => {
    try {
        console.log(`👤 [GET USER] Fetching current user: ${req.userId}`);
        const user = await User.findById(req.userId);
        console.log(
            `✅ [GET USER] User fetched successfully: ${user.username}`,
        );
        res.json(user.toJSON());
    } catch (error) {
        console.error(`❌ [GET USER ERROR] ${error.message}`);
        res.status(500).json({ error: error.message });
    }
};

const getAllUsers = async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 50;
        const offset = parseInt(req.query.offset) || 0;

        console.log(
            `👥 [GET ALL USERS] Fetching users - Limit: ${limit}, Offset: ${offset}`,
        );
        console.log(`   🔑 Current user ID (to exclude): ${req.userId}`);

        // Exclude current user
        const users = await User.find({ _id: { $ne: req.userId } })
            .limit(limit)
            .skip(offset)
            .select("-passwordHash");

        console.log(
            `✅ [GET ALL USERS] Found ${users.length} users (excluding current user)`,
        );
        console.log(
            `   📋 User IDs returned: ${users.map((u) => u._id).join(", ")}`,
        );
        res.json(users);
    } catch (error) {
        console.error(`❌ [GET ALL USERS ERROR] ${error.message}`);
        res.status(500).json({ error: error.message });
    }
};

module.exports = { getCurrentUser, getAllUsers };
