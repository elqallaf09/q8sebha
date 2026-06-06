const router = require('express').Router();
const db = require('../db/db');
const { authenticate } = require('../middleware/auth');

router.post('/', authenticate, async (req, res) => {
  const { product_id, notes } = req.body;
  if (!product_id) return res.status(400).json({ success: false, message: 'product_id مطلوب' });
  try {
    const product = (await db.query('SELECT * FROM products WHERE id=$1 AND is_available=1', [product_id])).rows[0];
    if (!product) return res.status(404).json({ success: false, message: 'المنتج غير موجود' });
    if (product.stock < 1) return res.status(400).json({ success: false, message: 'المنتج غير متوفر' });

    const orderNumber = `Q8S-${Date.now()}`;
    const { rows } = await db.query(
      `INSERT INTO orders (buyer_id,product_id,total_price,notes,order_number) VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [req.user.id, product_id, product.price, notes||null, orderNumber]);

    await db.query('UPDATE products SET stock=stock-1 WHERE id=$1', [product_id]);
    res.status(201).json({ success: true, data: rows[0] });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

router.get('/', authenticate, async (req, res) => {
  const { rows } = await db.query(
    `SELECT o.*,p.name AS product_name,p.emoji AS product_emoji FROM orders o JOIN products p ON p.id=o.product_id
     WHERE o.buyer_id=$1 ORDER BY o.created_at DESC`, [req.user.id]);
  res.json({ success: true, data: rows });
});

module.exports = router;
