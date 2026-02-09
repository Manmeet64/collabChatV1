/**
 * Generate a consistent private chat ID from two user IDs
 * Ensures the same chat ID regardless of which user initiates
 * @param {string} userId1 - First user ID
 * @param {string} userId2 - Second user ID
 * @returns {string} Consistent chat ID
 */
const generatePrivateChatId = (userId1, userId2) => {
  // Sort the IDs to ensure consistency
  const sorted = [userId1, userId2].sort();
  return `${sorted[0]}_${sorted[1]}`;
};

module.exports = { generatePrivateChatId };
