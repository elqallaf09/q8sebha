const router = require('express').Router();
const db = require('../db/db');
const { authenticate } = require('../middleware/auth');

// ─── GET /favorites — كل المفضلات ────────────────────────────────────────
router.get('/', authenticate, async (req, res) => {
  try {
    const { rows: products } = await db.query(`
      SELECT f.id AS fav_id, f.created_at AS saved_at,
             p.id, p.name, p.price, p.image_urls, p.emoji, p.stock, p.is_available
      FROM favorites f JOIN products p ON p.id = f.product_id
      WHERE f.user_id = $1 AND f.product_id IS NOT NULL
      ORDER BY f.created_at DESC`, [req.user.id]);

    const { rows: auctions } = await db.query(`
      SELECT f.id AS fav_id, f.created_at AS saved_at,
             a.id, a.title, a.current_price, a.image_urls, a.emoji, a.status, a.ends_at
      FROM favorites f JOIN auctions a ON a.id = f.auction_id
      WHERE f.user_id = $1 AND f.auction_id IS NOT NULL
      ORDER BY f.created_at DESC`, [req.user.id]);

    res.json({ success: true, data: { products, auctions } });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── POST /favorites/product/:id ─────────────────────────────────────────
router.post('/product/:id', authenticate, async (req, res) => {
  try {
    const existing = await db.query(
      'SELECT id FROM favorites WHERE user_id=$1 AND product_id=$2',
      [req.user.id, req.params.id]);

    if (existing.rows.length) {
      // إزالة من المفضلة
      await db.query('DELETE FROM favorites WHERE user_id=$1 AND product_id=$2',
        [req.user.id, req.params.id]);
      return res.json({ success: true, action: 'removed' });
    }
    await db.query('INSERT INTO favorites (user_id, product_id) VALUES ($1,$2)',
      [req.user.id, req.params.id]);
    res.json({ success: true, action: 'added' });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── POST /favorites/auction/:id ─────────────────────────────────────────
router.post('/auction/:id', authenticate, async (req, res) => {
  try {
    const existing = await db.query(
      'SELECT id FROM favorites WHERE user_id=$1 AND auction_id=$2',
      [req.user.id, req.params.id]);

    if (existing.rows.length) {
      await db.query('DELETE FROM favorites WHERE user_id=$1 AND auction_id=$2',
        [req.user.id, req.params.id]);
      return res.json({ success: true, action: 'removed' });
    }
    await db.query('INSERT INTO favorites (user_id, auction_id) VALUES ($1,$2)',
      [req.user.id, req.params.id]);
    res.json({ success: true, action: 'added' });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── GET /favorites/check?product_id=&auction_id= ────────────────────────
router.get('/check', authenticate, async (req, res) => {
  const { product_id, auction_id } = req.query;
  try {
    let row;
    if (product_id) {
      row = (await db.query(
        'SELECT id FROM favorites WHERE user_id=$1 AND product_id=$2',
        [req.user.id, product_id])).rows[0];
    } else if (auction_id) {
      row = (await db.query(
        'SELECT id FROM favorites WHERE user_id=$1 AND auction_id=$2',
        [req.user.id, auction_id])).rows[0];
    }
    res.json({ success: true, is_favorite: !!row });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

module.exports = router;
