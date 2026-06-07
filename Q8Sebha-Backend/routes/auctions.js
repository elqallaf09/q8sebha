const router = require('express').Router();
const { body, validationResult } = require('express-validator');
const db = require('../db/db');
const { authenticate } = require('../middleware/auth');
const { sendToToken } = require('../utils/fcm');

// ─── GET /auctions ────────────────────────────────────────────────────────
router.get('/', async (req, res) => {
  const { status='active', page=1, limit=20 } = req.query;
  const offset = (page-1)*limit;
  try {
    // إنهاء المزادات المنتهية — مع منطق reserve_price
    // إذا المزايد موجود لكن السعر أقل من reserve_price → reserve_not_met
    await db.query(`
      UPDATE auctions SET
        status = CASE
          WHEN reserve_price IS NOT NULL AND current_price < reserve_price THEN 'reserve_not_met'
          WHEN current_bidder_id IS NOT NULL THEN 'ended'
          ELSE 'no_bids'
        END,
        winner_id = CASE
          WHEN reserve_price IS NOT NULL AND current_price < reserve_price THEN NULL
          ELSE current_bidder_id
        END,
        final_price = CASE
          WHEN reserve_price IS NOT NULL AND current_price < reserve_price THEN NULL
          ELSE current_price
        END
      WHERE status='active' AND ends_at<=NOW()
    `);

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
          reserve_price, bid_increment=1.0, seller_terms, duration_minutes, listing_fee=2.0 } = req.body;
  const endsAt = new Date(Date.now() + duration_minutes*60*1000);

  try {
    const { rows } = await db.query(`
      INSERT INTO auctions (seller_id,title,description,image_urls,emoji,starting_price,max_price,
        reserve_price,bid_increment,current_price,seller_terms,duration_minutes,ends_at,listing_fee)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14) RETURNING *`,
      [req.user.id, title, description||null, JSON.stringify(image_urls), emoji,
       starting_price, max_price||null, reserve_price||null, bid_increment, starting_price,
       seller_terms||null, duration_minutes, endsAt, listing_fee]);

    // ─── إشعار لجميع المستخدمين ──────────────────────────────────────────
    const durText = duration_minutes < 60
      ? `${duration_minutes} دقيقة`
      : duration_minutes < 1440
        ? `${Math.floor(duration_minutes/60)} ساعة`
        : `${Math.floor(duration_minutes/1440)} يوم`;
    const notifTitle = '🔨 مزاد جديد!';
    const notifBody  = `${title} — ابتداءً من ${starting_price} د.ك — المدة: ${durText}`;

    const allUsers = (await db.query("SELECT id, device_token FROM users WHERE id != $1", [req.user.id])).rows;
    const deviceTokens = [];

    for (const u of allUsers) {
      await db.query(
        `INSERT INTO notifications (user_id,type,title,body,icon,data) VALUES ($1,'auction',$2,$3,'🔨',$4)`,
        [u.id, notifTitle, notifBody, JSON.stringify({ auction_id: rows[0].id })]
      );
      if (u.device_token) deviceTokens.push(u.device_token);
    }

    // إرسال FCM push notification للجميع
    const { sendToTokens } = require('../utils/fcm');
    setImmediate(() =>
      sendToTokens(deviceTokens, notifTitle, notifBody,
        { type: 'new_auction', auction_id: String(rows[0].id) })
    );

    // WebSocket broadcast
    const wsMsg = JSON.stringify({ type: 'new_auction', auction: rows[0] });
    if (global.wsClients) Object.values(global.wsClients).forEach(ws => { try { ws.send(wsMsg); } catch(_){} });

    res.status(201).json({ success: true, data: rows[0] });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── POST /auctions/:id/bid ───────────────────────────────────────────────
router.post('/:id/bid', authenticate, async (req, res) => {
  const auctionId = +req.params.id;
  const amount    = +req.body.amount;

  // تحقق أساسي من المدخلات
  if (!amount || isNaN(amount) || amount <= 0)
    return res.status(400).json({ success: false, message: 'مبلغ المزايدة غير صالح' });

  const client = await db.connect();
  try {
    await client.query('BEGIN');

    // قفل الصف للحماية من race conditions
    const { rows } = await client.query(
      'SELECT * FROM auctions WHERE id=$1 FOR UPDATE', [auctionId]);
    const auction = rows[0];

    if (!auction) { await client.query('ROLLBACK'); return res.status(404).json({ success: false, message: 'المزاد غير موجود' }); }
    if (auction.status !== 'active') { await client.query('ROLLBACK'); return res.status(400).json({ success: false, message: 'المزاد منتهٍ' }); }
    if (new Date() > new Date(auction.ends_at)) { await client.query('ROLLBACK'); return res.status(400).json({ success: false, message: 'انتهى وقت المزاد' }); }
    if (auction.seller_id === req.user.id) { await client.query('ROLLBACK'); return res.status(400).json({ success: false, message: 'لا يمكنك المزايدة على مزادك' }); }

    const minValid = +auction.current_price + +auction.bid_increment;
    if (amount < minValid) { await client.query('ROLLBACK'); return res.status(400).json({ success: false, message: `الحد الأدنى للمزايدة ${minValid.toFixed(3)} د.ك` }); }
    if (auction.max_price && amount > +auction.max_price) { await client.query('ROLLBACK'); return res.status(400).json({ success: false, message: 'تجاوز الحد الأعلى للمزاد' }); }

    const bid = (await client.query(
      'INSERT INTO bids (auction_id,bidder_id,amount) VALUES ($1,$2,$3) RETURNING *',
      [auctionId, req.user.id, amount]
    )).rows[0];

    await client.query(
      'UPDATE auctions SET current_price=$1, current_bidder_id=$2, bids_count=bids_count+1 WHERE id=$3',
      [amount, req.user.id, auctionId]);

    await client.query('COMMIT');

    const updatedAuction = (await db.query('SELECT * FROM auctions WHERE id=$1', [auctionId])).rows[0];

    // WebSocket
    const msg = JSON.stringify({ type:'new_bid', auctionId, amount: +amount, bidderName: req.user.name });
    if (global.wsClients) Object.values(global.wsClients).forEach(ws => { try { ws.send(msg); } catch(_){} });

    // ─── FCM: أشعر البائع والمزايد السابق ────────────────────────────
    setImmediate(async () => {
      try {
        // جلب token البائع
        const sellerRow = await db.query('SELECT device_token FROM users WHERE id=$1', [auction.seller_id]);
        const sellerToken = sellerRow.rows[0]?.device_token;
        if (sellerToken && auction.seller_id !== req.user.id) {
          await sendToToken(sellerToken,
            '🎉 مزايدة جديدة!',
            `مزايدة بـ ${(+amount).toFixed(3)} د.ك على "${auction.title}"`,
            { type: 'new_bid', auction_id: String(auctionId) }
          );
        }
        // أشعر المزايد السابق إذا كان موجوداً وهو مختلف
        if (auction.current_bidder_id && auction.current_bidder_id !== req.user.id) {
          const prevRow = await db.query('SELECT device_token FROM users WHERE id=$1', [auction.current_bidder_id]);
          const prevToken = prevRow.rows[0]?.device_token;
          if (prevToken) {
            await sendToToken(prevToken,
              '⚠️ تجاوزوا مزايدتك!',
              `تم تجاوز مزايدتك على "${auction.title}" — زايد الآن!`,
              { type: 'outbid', auction_id: String(auctionId) }
            );
          }
        }
      } catch (_) {}
    });

    res.json({ success: true, data: { bid: { ...bid, bidder_name: req.user.name }, auction: updatedAuction } });
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch(_) {}
    res.status(500).json({ success: false, message: err.message });
  } finally {
    client.release();
  }
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

// ─── GET /auctions/:id/bids — سجل المزايدات ──────────────────────────────
router.get('/:id/bids', async (req, res) => {
  try {
    const { rows } = await db.query(`
      SELECT b.id, b.amount, b.created_at,
             u.name AS bidder_name
      FROM bids b JOIN users u ON u.id = b.bidder_id
      WHERE b.auction_id = $1
      ORDER BY b.amount DESC`, [req.params.id]);
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── POST /auctions/:id/auto-bid — ضبط مزايدة تلقائية ───────────────────
router.post('/:id/auto-bid', authenticate, async (req, res) => {
  const { max_amount } = req.body;
  const auctionId = +req.params.id;
  if (!max_amount || +max_amount <= 0) return res.status(400).json({ success: false, message: 'أدخل الحد الأعلى' });

  try {
    const auction = (await db.query('SELECT * FROM auctions WHERE id=$1', [auctionId])).rows[0];
    if (!auction) return res.status(404).json({ success: false, message: 'المزاد غير موجود' });
    if (auction.status !== 'active') return res.status(400).json({ success: false, message: 'المزاد منتهٍ' });
    if (auction.seller_id === req.user.id) return res.status(400).json({ success: false, message: 'لا يمكنك المزايدة على مزادك' });
    if (+max_amount <= +auction.current_price) return res.status(400).json({ success: false, message: `الحد الأعلى يجب أن يكون أكثر من ${auction.current_price} د.ك` });

    // حفظ أو تحديث المزايدة التلقائية
    await db.query(`
      INSERT INTO auto_bids (user_id, auction_id, max_amount, is_active)
      VALUES ($1, $2, $3, 1)
      ON CONFLICT (user_id, auction_id) DO UPDATE SET max_amount=$3, is_active=1`,
      [req.user.id, auctionId, +max_amount]);

    // مزايدة فورية بالحد الأدنى الممكن
    const nextBid = +auction.current_price + +auction.bid_increment;
    if (nextBid <= +max_amount) {
      await db.query('INSERT INTO bids (auction_id,bidder_id,amount) VALUES ($1,$2,$3)',
        [auctionId, req.user.id, nextBid]);
      await db.query('UPDATE auctions SET current_price=$1, current_bidder_id=$2, bids_count=bids_count+1 WHERE id=$3',
        [nextBid, req.user.id, auctionId]);

      const msg = JSON.stringify({ type:'new_bid', auctionId, amount: nextBid, bidderName: req.user.name, auto: true });
      if (global.wsClients) Object.values(global.wsClients).forEach(ws => { try { ws.send(msg); } catch(_){} });
    }

    res.json({ success: true, message: `تم تفعيل المزايدة التلقائية حتى ${max_amount} د.ك` });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── GET /auctions/:id/auto-bid — حالة المزايدة التلقائية ────────────────
router.get('/:id/auto-bid', authenticate, async (req, res) => {
  try {
    const { rows } = await db.query(
      'SELECT * FROM auto_bids WHERE user_id=$1 AND auction_id=$2 AND is_active=1',
      [req.user.id, req.params.id]);
    res.json({ success: true, data: rows[0] || null });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── DELETE /auctions/:id/auto-bid — إلغاء المزايدة التلقائية ────────────
router.delete('/:id/auto-bid', authenticate, async (req, res) => {
  try {
    await db.query('UPDATE auto_bids SET is_active=0 WHERE user_id=$1 AND auction_id=$2',
      [req.user.id, req.params.id]);
    res.json({ success: true, message: 'تم إلغاء المزايدة التلقائية' });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── POST /auctions/:id/report ────────────────────────────────────────────
router.post('/:id/report', authenticate, async (req, res) => {
  const auction = (await db.query('SELECT * FROM auctions WHERE id=$1', [req.params.id])).rows[0];
  if (!auction || auction.seller_id !== req.user.id) return res.status(403).json({ success: false, message: 'غير مصرح' });
  if (auction.winner_id) await db.query("UPDATE users SET is_banned=1, ban_reason='عدم الدفع في المزاد' WHERE id=$1", [auction.winner_id]);
  res.json({ success: true, message: 'تم الإبلاغ وحظر المشتري' });
});

module.exports = router;
