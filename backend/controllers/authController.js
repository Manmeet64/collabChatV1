const User = require('../models/User');
const jwt = require('jsonwebtoken');

const register = async (req, res) => {
  try {
    const { username, password } = req.body;
    console.log(`📝 [REGISTER] Attempting to register user: ${username}`);

    // Validation
    if (!username || !password) {
      console.log(`❌ [REGISTER] Missing credentials for user: ${username}`);
      return res.status(400).json({ error: 'Username and password required' });
    }

    // Check if user exists
    const existingUser = await User.findOne({ username });
    if (existingUser) {
      console.log(`❌ [REGISTER] Username already exists: ${username}`);
      return res.status(400).json({ error: 'Username already exists' });
    }

    // Create user
    const user = new User({
      username,
      passwordHash: password,
    });

    await user.save();
    console.log(`✅ [REGISTER] User created successfully: ${username} (ID: ${user._id})`);

    // Generate token
    const token = jwt.sign(
      { userId: user._id, username: user.username },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE }
    );

    console.log(`🔐 [REGISTER] JWT token generated for: ${username}`);

    res.status(201).json({
      token,
      user: user.toJSON(),
    });
  } catch (error) {
    console.error(`❌ [REGISTER ERROR] ${error.message}`);
    res.status(500).json({ error: error.message });
  }
};

const login = async (req, res) => {
  try {
    const { username, password } = req.body;
    console.log(`🔑 [LOGIN] Attempting to login user: ${username}`);

    if (!username || !password) {
      console.log(`❌ [LOGIN] Missing credentials for user: ${username}`);
      return res.status(400).json({ error: 'Username and password required' });
    }

    // Find user
    const user = await User.findOne({ username }).select('+passwordHash');
    if (!user) {
      console.log(`❌ [LOGIN] User not found: ${username}`);
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      console.log(`❌ [LOGIN] Invalid password for user: ${username}`);
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Update online status
    user.isOnline = true;
    await user.save();
    console.log(`✅ [LOGIN] User logged in successfully: ${username}`);

    // Generate token
    const token = jwt.sign(
      { userId: user._id, username: user.username },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE }
    );

    console.log(`🔐 [LOGIN] JWT token generated for: ${username}`);

    res.json({
      token,
      user: user.toJSON(),
    });
  } catch (error) {
    console.error(`❌ [LOGIN ERROR] ${error.message}`);
    res.status(500).json({ error: error.message });
  }
};

module.exports = { register, login };
