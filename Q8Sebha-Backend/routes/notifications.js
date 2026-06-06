const router = require('express').Router();
const db = require('../db/db');
const { authenticate } = require('../middleware/auth');

router.get('/', authenticate, async (req, res) => {
  const { page=1, limit=20 } = req.query;
  const offset = (page-1)*limit;
  const { rows } = await db.query(
    `SELECT * FROM notifications WHERE user_id=$1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`,
    [req.user.id, +limit, +offset]);
  const total = (await db.query('SELECT COUNT(*) FROM notifications WHERE user_id=$1', [req.user.id])).rows[0].count;
  const unread = (await db.query('SELECT COUNT(*) FROM notifications WHERE user_id=$1 AND is_read=0', [req.user.id])).rows[0].count;
  res.json({ success: true, data: rows, meta: { total: +total, unread: +unread } });
});

router.patch('/:id/read', authenticate, async (req, res) => {
  await db.query('UPDATE notifications SET is_read=1 WHERE id=$1 AND user_id=$2', [req.params.id, req.user.id]);
  res.json({ success: true });
});

router.post('/read-all', authenticate, async (req, res) => {
  await db.query('UPDATE notifications SET is_read=1 WHERE user_id=$1', [req.user.id]);
  res.json({ success: true });
});

module.exports = router;
