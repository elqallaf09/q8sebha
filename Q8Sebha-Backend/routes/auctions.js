const router = require('express').Router();
const { body, validationResult } = require('express-validator');
const db = require('../db/db');
const { authenticate } = require('../middleware/auth');

// ─── GET /auctions ────────────────────────────────────────────────────────
router.get('/', async (req, res) => {
  const { status='active', page=1, limit=20 } = req.query;
  const offset = (page-1)*limit;
  try {
    // إنهاء المزادات المنتهية
    await db.query(`UPDATE auctions SET status='ended', winner_id=current_bidder_id, final_price=current_price
                    WHERE status='active' AND ends_at<=NOW() AND current_bidder_id IS NOT NULL`);

    const { rows } = await db.query(`
      SELECT a.*, u.name AS seller_name, u.phone AS seller_phone, u.contact_method AS seller_contact,
             (SELECT COUNT(*) FROM bids WHERE auction_id=a.id) AS total_bids
      FROM auctions a JOIN users u ON u.id=a.seller_id
      WHERE a.status=$1 ORDER BY a.ends_at ASC LIMIT $2 OFFSET $3`,
      [status, +limit, +offset]);

    const total = (await db.query('SELECT COUNT(*) FROM auctions WHERE status=$1', [status])).rows[0].count;
    res.json({ success: true, data: rows, meta: { total: +total, page: +page, limit: +limit } });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── GET /auctions/:id ────────────────────────────────────────────────────
router.get('/:id', async (req, res) => {
  try {
    const { rows } = await db.query(`
      SELECT a.*, u.name AS seller_name, u.phone AS seller_phone, u.contact_method AS seller_contact,
             w.name AS winner_name, w.phone AS winner_phone
      FROM auctions a JOIN users u ON u.id=a.seller_id LEFT JOIN users w ON w.id=a.winner_id
      WHERE a.id=$1`, [req.params.id]);

    if (!rows.length) return res.status(404).json({ success: false, message: 'المزاد غير موجود' });

    const bids = (await db.query(`
      SELECT b.*, u.name AS bidder_name FROM bids b JOIN users u ON u.id=b.bidder_id
      WHERE b.auction_id=$1 ORDER BY b.amount DESC LIMIT 10`, [req.params.id])).rows;

    res.json({ success: true, data: { ...rows[0], recent_bids: bids } });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── POST /auctions ───────────────────────────────────────────────────────
router.post('/', authenticate, [
  body('title').trim().notEmpty(),
  body('starting_price').isFloat({ min: 1 }),
  body('duration_minutes').isInt({ min: 1, max: 1440 }),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, errors: errors.array() });

  const { title, description, image_urls=[], emoji='📿', starting_price, max_price,
          bid_increment=1.0, seller_terms, duration_minutes, listing_fee=2.0 } = req.body;
  const endsAt = new Date(Date.now() + duration_minutes*60*1000);

  try {
    const { rows } = await db.query(`
      INSERT INTO auctions (seller_id,title,description,image_urls,emoji,starting_price,max_price,
        bid_increment,current_price,seller_terms,duration_minutes,ends_at,listing_fee)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13) RETURNING *`,
      [req.user.id, title, description||null, JSON.stringify(image_urls), emoji,
       starting_price, max_price||null, bid_increment, starting_price,
       seller_terms||null, duration_minutes, endsAt, listing_fee]);

    // إشعار الأدمن
    const admins = (await db.query("SELECT id FROM users WHERE role='admin'")).rows;
    for (const admin of admins) {
      await db.query(`INSERT INTO notifications (user_id,type,title,body,icon,data) VALUES ($1,'system',$2,$3,'🔨',$4)`,
        [admin.id, 'مزاد جديد نُشر', `${req.user.name} نشر مزاداً: ${title}`, JSON.stringify({ auction_id: rows[0].id })]);
    }
    res.status(201).json({ success: true, data: rows[0] });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── POST /auctions/:id/bid ───────────────────────────────────────────────
router.post('/:id/bid', authenticate, async (req, res) => {
  const auctionId = +req.params.id;
  const { amount } = req.body;
  try {
    const auction = (await db.query('SELECT * FROM auctions WHERE id=$1', [auctionId])).rows[0];
    if (!auction) return res.status(404).json({ success: false, message: 'المزاد غير موجود' });
    if (auction.status !== 'active') return res.status(400).json({ success: false, message: 'المزاد منتهٍ' });
    if (new Date() > new Date(auction.ends_at)) return res.status(400).json({ success: false, message: 'انتهى وقت المزاد' });
    if (+amount <= +auction.current_price) return res.status(400).json({ success: false, message: `المزايدة يجب أن تكون أكثر من ${auction.current_price}` });
    if (auction.max_price && +amount > +auction.max_price) return res.status(400).json({ success: false, message: 'تجاوز الحد الأعلى' });
    if (auction.seller_id === req.user.id) return res.status(400).json({ success: false, message: 'لا يمكنك المزايدة على مزادك' });

    const bid = (await db.query(
      'INSERT INTO bids (auction_id,bidder_id,amount) VALUES ($1,$2,$3) RETURNING *',
      [auctionId, req.user.id, amount]
    )).rows[0];

    await db.query('UPDATE auctions SET current_price=$1, current_bidder_id=$2, bids_count=bids_count+1 WHERE id=$3',
      [amount, req.user.id, auctionId]);

    const updatedAuction = (await db.query('SELECT * FROM auctions WHERE id=$1', [auctionId])).rows[0];

    // WebSocket
    const msg = JSON.stringify({ type:'new_bid', auctionId, amount: +amount, bidderName: req.user.name });
    if (global.wsClients) Object.values(global.wsClients).forEach(ws => { try { ws.send(msg); } catch(_){} });

    res.json({ success: true, data: { bid: { ...bid, bidder_name: req.user.name }, auction: updatedAuction } });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── POST /auctions/:id/payment-link ─────────────────────────────────────
router.post('/:id/payment-link', authenticate, async (req, res) => {
  const { payment_link } = req.body;
  const auction = (await db.query('SELECT * FROM auctions WHERE id=$1', [req.params.id])).rows[0];
  if (!auction || auction.seller_id !== req.user.id) return res.status(403).json({ success: false, message: 'غير مصرح' });
  await db.query('UPDATE auctions SET payment_link=$1 WHERE id=$2', [payment_link, req.params.id]);
  if (auction.winner_id) {
    await db.query(`INSERT INTO notifications (user_id,type,title,body,icon,data) VALUES ($1,'payment',$2,$3,'💳',$4)`,
      [auction.winner_id, 'رابط الدفع جاهز', `البائع أرسل رابط الدفع للمزاد: ${auction.title}`,
       JSON.stringify({ auction_id: auction.id, payment_link })]);
  }
  res.json({ success: true });
});

// ─── POST /auctions/:id/report ────────────────────────────────────────────
router.post('/:id/report', authenticate, async (req, res) => {
  const auction = (await db.query('SELECT * FROM auctions WHERE id=$1', [req.params.id])).rows[0];
  if (!auction || auction.seller_id !== req.user.id) return res.status(403).json({ success: false, message: 'غير مصرح' });
  if (auction.winner_id) await db.query("UPDATE users SET is_banned=1, ban_reason='عدم الدفع في المزاد' WHERE id=$1", [auction.winner_id]);
  res.json({ success: true, message: 'تم الإبلاغ وحظر المشتري' });
});

module.exports = router;
