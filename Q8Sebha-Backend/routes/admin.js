const router = require('express').Router();
const db = require('../db/db');
const { authenticate, adminOnly } = require('../middleware/auth');

// تغليف async handlers لمنع UnhandledPromiseRejection
const h = fn => (req, res, next) => fn(req, res, next).catch(next);

router.use(authenticate, adminOnly);

router.get('/stats', h(async (req, res) => {
  const [usersR, auctionsR, productsR, ordersR, revenueR, bannedR, pendingR] = await Promise.all([
    db.query('SELECT COUNT(*) FROM users'),
    db.query("SELECT COUNT(*) FROM auctions WHERE status='active'"),
    db.query('SELECT COUNT(*) FROM products WHERE is_available=1'),
    db.query('SELECT COUNT(*) FROM orders'),
    db.query("SELECT COALESCE(SUM(total_price),0) AS total FROM orders WHERE status NOT IN ('cancelled')"),
    db.query('SELECT COUNT(*) FROM users WHERE is_banned=1'),
    db.query("SELECT COUNT(*) FROM orders WHERE status='pending'"),
  ]);
  res.json({ success: true, data: {
    users:           +usersR.rows[0].count,
    active_auctions: +auctionsR.rows[0].count,
    products:        +productsR.rows[0].count,
    orders:          +ordersR.rows[0].count,
    orders_total:    parseFloat(revenueR.rows[0].total).toFixed(3),
    banned_users:    +bannedR.rows[0].count,
    pending_orders:  +pendingR.rows[0].count,
  }});
}));

router.get('/users', h(async (req, res) => {
  const { page=1, limit=50, search='' } = req.query;
  const offset = (page-1)*limit;
  const q = `%${search}%`;
  const { rows } = await db.query(
    `SELECT id,name,phone,email,role,is_banned,created_at
     FROM users WHERE name ILIKE $1 OR phone ILIKE $1 OR email ILIKE $1
     ORDER BY created_at DESC LIMIT $2 OFFSET $3`,
    [q, limit, offset]);
  res.json({ success: true, data: rows });
}));

router.patch('/users/:id/ban', h(async (req, res) => {
  const { reason } = req.body;
  await db.query("UPDATE users SET is_banned=1, ban_reason=$1 WHERE id=$2",
    [reason||'مخالفة الشروط', req.params.id]);
  res.json({ success: true });
}));

router.patch('/users/:id/unban', h(async (req, res) => {
  await db.query('UPDATE users SET is_banned=0, ban_reason=NULL WHERE id=$1', [req.params.id]);
  res.json({ success: true });
}));

router.patch('/users/:id/role', h(async (req, res) => {
  const { role } = req.body;
  if (!['user','admin','seller'].includes(role))
    return res.status(400).json({ success: false, message: 'دور غير صالح' });
  await db.query('UPDATE users SET role=$1 WHERE id=$2', [role, req.params.id]);
  res.json({ success: true });
}));

router.get('/auctions', h(async (req, res) => {
  const { rows } = await db.query(
    `SELECT a.*,u.name AS seller_name FROM auctions a
     JOIN users u ON u.id=a.seller_id ORDER BY a.created_at DESC LIMIT 100`);
  res.json({ success: true, data: rows });
}));

router.delete('/auctions/:id', h(async (req, res) => {
  await db.query("UPDATE auctions SET status='removed' WHERE id=$1", [req.params.id]);
  res.json({ success: true });
}));

router.get('/categories', h(async (req, res) => {
  const { rows } = await db.query('SELECT * FROM categories ORDER BY sort_order');
  res.json({ success: true, data: rows });
}));

router.post('/categories', h(async (req, res) => {
  const { name, name_en, parent_id, icon='📿', sort_order=0 } = req.body;
  if (!name||!name_en)
    return res.status(400).json({ success: false, message: 'name و name_en مطلوبان' });
  const { rows } = await db.query(
    'INSERT INTO categories (name,name_en,parent_id,icon,sort_order) VALUES ($1,$2,$3,$4,$5) RETURNING *',
    [name, name_en, parent_id||null, icon, sort_order]);
  res.status(201).json({ success: true, data: rows[0] });
}));

router.delete('/categories/:id', h(async (req, res) => {
  await db.query('DELETE FROM categories WHERE id=$1', [req.params.id]);
  res.json({ success: true });
}));

module.exports = router;
