const router = require('express').Router();
const db     = require('../db/db');
const { authenticate } = require('../middleware/auth');

// جميع routes تتطلب مصادقة
router.use(authenticate);

// GET /cart — جلب سلة المستخدم
router.get('/', async (req, res) => {
  try {
    const { rows } = await db.query(`
      SELECT ci.id, ci.quantity, ci.notes,
             p.id AS product_id, p.name, p.price, p.emoji, p.image_urls,
             p.stock, p.is_available
      FROM cart_items ci
      JOIN products p ON p.id = ci.product_id
      WHERE ci.user_id = $1
      ORDER BY ci.created_at DESC
    `, [req.user.id]);
    res.json({ success: true, data: rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /cart — إضافة منتج للسلة
router.post('/', async (req, res) => {
  const { product_id, quantity = 1, notes } = req.body;
  if (!product_id) return res.status(400).json({ success: false, message: 'product_id مطلوب' });

  try {
    // تحقق من وجود المنتج
    const { rows: prod } = await db.query(
      'SELECT id, stock, is_available FROM products WHERE id=$1', [product_id]);
    if (!prod.length || prod[0].is_available != 1)
      return res.status(404).json({ success: false, message: 'المنتج غير متاح' });

    // إضافة أو تحديث الكمية
    const { rows } = await db.query(`
      INSERT INTO cart_items (user_id, product_id, quantity, notes)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (user_id, product_id)
      DO UPDATE SET quantity = cart_items.quantity + $3, notes = EXCLUDED.notes
      RETURNING *
    `, [req.user.id, product_id, quantity, notes || null]);

    res.status(201).json({ success: true, data: rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /cart/:id — تحديث الكمية
router.patch('/:id', async (req, res) => {
  const { quantity } = req.body;
  if (!quantity || quantity < 1)
    return res.status(400).json({ success: false, message: 'كمية غير صالحة' });

  try {
    const { rows } = await db.query(
      'UPDATE cart_items SET quantity=$1 WHERE id=$2 AND user_id=$3 RETURNING *',
      [quantity, req.params.id, req.user.id]);
    if (!rows.length) return res.status(404).json({ success: false, message: 'العنصر غير موجود' });
    res.json({ success: true, data: rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /cart/:id — حذف عنصر
router.delete('/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM cart_items WHERE id=$1 AND user_id=$2', [req.params.id, req.user.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /cart — تفريغ السلة
router.delete('/', async (req, res) => {
  try {
    await db.query('DELETE FROM cart_items WHERE user_id=$1', [req.user.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
