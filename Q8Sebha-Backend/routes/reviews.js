const router = require('express').Router();
const db = require('../db/db');
const { authenticate } = require('../middleware/auth');

// ─── POST /reviews — إضافة تقييم ─────────────────────────────────────────
router.post('/', authenticate, async (req, res) => {
  const { seller_id, auction_id, rating, comment } = req.body;
  if (!seller_id || !rating) return res.status(400).json({ success: false, message: 'seller_id و rating مطلوبان' });
  if (+rating < 1 || +rating > 5) return res.status(400).json({ success: false, message: 'التقييم بين 1 و 5' });
  if (+seller_id === req.user.id) return res.status(400).json({ success: false, message: 'لا يمكنك تقييم نفسك' });

  try {
    // التحقق من عدم وجود تقييم مسبق لنفس المزاد
    if (auction_id) {
      const dup = await db.query(
        'SELECT id FROM reviews WHERE reviewer_id=$1 AND auction_id=$2',
        [req.user.id, auction_id]);
      if (dup.rows.length) return res.status(409).json({ success: false, message: 'قيّمت هذا المزاد مسبقاً' });
    }

    await db.query(
      `INSERT INTO reviews (reviewer_id, seller_id, auction_id, rating, comment)
       VALUES ($1, $2, $3, $4, $5)`,
      [req.user.id, seller_id, auction_id||null, +rating, comment||null]);

    // تحديث متوسط تقييم البائع
    await db.query(`
      UPDATE users SET rating = (
        SELECT ROUND(AVG(rating)::numeric, 1) FROM reviews WHERE seller_id = $1
      ) WHERE id = $1`, [seller_id]);

    res.json({ success: true, message: 'تم إضافة تقييمك بنجاح' });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── GET /reviews/seller/:id — تقييمات بائع معين ─────────────────────────
router.get('/seller/:id', async (req, res) => {
  try {
    const { rows } = await db.query(`
      SELECT r.id, r.rating, r.comment, r.created_at,
             u.name AS reviewer_name,
             a.title AS auction_title
      FROM reviews r
      JOIN users u ON u.id = r.reviewer_id
      LEFT JOIN auctions a ON a.id = r.auction_id
      WHERE r.seller_id = $1
      ORDER BY r.created_at DESC
      LIMIT 20`, [req.params.id]);

    // متوسط حقيقي فقط — لا قيم وهمية
    const avg = rows.length
      ? +(rows.reduce((s, r) => s + +r.rating, 0) / rows.length).toFixed(1)
      : null;

    res.json({
      success: true,
      data: {
        reviews: rows,
        average: avg,      // null إذا لا يوجد أي تقييم
        count: rows.length,
      }
    });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

module.exports = router;
