const router = require('express').Router();
const db = require('../db/db');
const { authenticate, adminOnly } = require('../middleware/auth');

router.use(authenticate, adminOnly);

router.get('/stats', async (req, res) => {
  try {
    const users    = (await db.query('SELECT COUNT(*) FROM users')).rows[0].count;
    const auctions = (await db.query("SELECT COUNT(*) FROM auctions WHERE status='active'")).rows[0].count;
    const products = (await db.query('SELECT COUNT(*) FROM products WHERE is_available=1')).rows[0].count;
    const orders   = (await db.query('SELECT COUNT(*) FROM orders')).rows[0].count;
    res.json({ success: true, data: { users:+users, active_auctions:+auctions, products:+products, orders:+orders } });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

router.get('/users', async (req, res) => {
  const { rows } = await db.query('SELECT id,name,phone,email,role,is_banned,created_at FROM users ORDER BY created_at DESC');
  res.json({ success: true, data: rows });
});

router.patch('/users/:id/ban', async (req, res) => {
  const { reason } = req.body;
  await db.query("UPDATE users SET is_banned=1, ban_reason=$1 WHERE id=$2", [reason||'مخالفة الشروط', req.params.id]);
  res.json({ success: true });
});

router.patch('/users/:id/unban', async (req, res) => {
  await db.query('UPDATE users SET is_banned=0, ban_reason=NULL WHERE id=$1', [req.params.id]);
  res.json({ success: true });
});

router.patch('/users/:id/role', async (req, res) => {
  const { role } = req.body;
  if (!['user','admin','seller'].includes(role)) return res.status(400).json({ success: false, message: 'دور غير صالح' });
  await db.query('UPDATE users SET role=$1 WHERE id=$2', [role, req.params.id]);
  res.json({ success: true });
});

router.get('/auctions', async (req, res) => {
  const { rows } = await db.query(
    `SELECT a.*,u.name AS seller_name FROM auctions a JOIN users u ON u.id=a.seller_id ORDER BY a.created_at DESC LIMIT 50`);
  res.json({ success: true, data: rows });
});

router.delete('/auctions/:id', async (req, res) => {
  await db.query("UPDATE auctions SET status='removed' WHERE id=$1", [req.params.id]);
  res.json({ success: true });
});

router.get('/categories', async (req, res) => {
  const { rows } = await db.query('SELECT * FROM categories ORDER BY sort_order');
  res.json({ success: true, data: rows });
});

router.post('/categories', async (req, res) => {
  const { name, name_en, parent_id, icon='📿', sort_order=0 } = req.body;
  if (!name||!name_en) return res.status(400).json({ success: false, message: 'name و name_en مطلوبان' });
  const { rows } = await db.query(
    'INSERT INTO categories (name,name_en,parent_id,icon,sort_order) VALUES ($1,$2,$3,$4,$5) RETURNING *',
    [name, name_en, parent_id||null, icon, sort_order]);
  res.status(201).json({ success: true, data: rows[0] });
});

router.delete('/categories/:id', async (req, res) => {
  await db.query('DELETE FROM categories WHERE id=$1', [req.params.id]);
  res.json({ success: true });
});

module.exports = router;
