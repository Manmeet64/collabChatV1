const express = require('express');
const authMiddleware = require('../middleware/auth');
const {
  createGroup,
  getMyGroups,
  addGroupMember,
} = require('../controllers/groupsController');

const router = express.Router();

router.post('/', authMiddleware, createGroup);
router.get('/my', authMiddleware, getMyGroups);
router.post('/:groupId/add', authMiddleware, addGroupMember);

module.exports = router;
