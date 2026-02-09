const express = require('express');
const authMiddleware = require('../middleware/auth');
const { getCurrentUser, getAllUsers } = require('../controllers/usersController');

const router = express.Router();

router.get('/me', authMiddleware, getCurrentUser);
router.get('/', authMiddleware, getAllUsers);

module.exports = router;
