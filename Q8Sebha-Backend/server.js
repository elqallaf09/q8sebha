require('dns').setDefaultResultOrder('ipv4first'); // Railway → Supabase IPv4 fix
require('dotenv').config();
const express     = require('express');
const cors        = require('cors');
const helmet      = require('helmet');
const morgan      = require('morgan');
const rateLimit   = require('express-rate-limit');
const { WebSocketServer } = require('ws');
const http        = require('http');
const path        = require('path');

const db     = require('./db/db');
const app    = express();
const server = http.createServer(app);

// ─── Firebase Admin / FCM ─────────────────────────────────────────────────
// ضع مسار ملف serviceAccountKey.json أو استخدم متغيرات البيئة
try {
  const admin = require('firebase-admin');

  // الطريقة 1: ملف JSON (محلياً)
  // const serviceAccount = require('./firebase-service-account.json');
  // admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

  // الطريقة 2: متغيرات البيئة على Railway (موصى بها)
  if (process.env.FIREBASE_PROJECT_ID) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId:    process.env.FIREBASE_PROJECT_ID,
        clientEmail:  process.env.FIREBASE_CLIENT_EMAIL,
        privateKey:   process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      }),
    });
    global.fcmAdmin = admin;
    console.log('✅ Firebase FCM جاهز');
  } else {
    console.warn('⚠️  FIREBASE_* env vars not set — FCM disabled');
    global.fcmAdmin = null;
  }
} catch (e) {
  console.warn('⚠️  firebase-admin not available:', e.message);
  global.fcmAdmin = null;
}

app.use(helmet());
app.use(cors({ origin: '*', methods: ['GET','POST','PUT','PATCH','DELETE'] }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

const limiter     = rateLimit({ windowMs: 15*60*1000, max: 200 });
const authLimiter = rateLimit({ windowMs: 15*60*1000, max: 20 });
app.use('/api/', limiter);
app.use('/api/auth/login',    authLimiter);
app.use('/api/auth/register', authLimiter);

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ─── WebSocket ────────────────────────────────────────────────────────────
const wss = new WebSocketServer({ server, path: '/ws' });
global.wsClients = {};
wss.on('connection', (ws, req) => {
  const userId = new URL(req.url, 'http://localhost').searchParams.get('user_id');
  if (userId) global.wsClients[userId] = ws;
  ws.on('close', () => { if (userId) delete global.wsClients[userId]; });
  ws.send(JSON.stringify({ type: 'connected' }));
});

// ─── Routes ───────────────────────────────────────────────────────────────
app.use('/api/auth',          require('./routes/auth'));
app.use('/api/upload',        require('./routes/upload'));
app.use('/api/auctions',      require('./routes/auctions'));
app.use('/api/orders',        require('./routes/orders'));
app.use('/api/products',      require('./routes/products'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/admin',         require('./routes/admin'));
app.use('/api/favorites',     require('./routes/favorites'));
app.use('/api/reviews',       require('./routes/reviews'));

app.get('/health', async (_, res) => {
  try {
    const { rows } = await db.query("SELECT COUNT(*) as cnt FROM users");
    res.json({ status: 'ok', service: 'Q8Sebha API', users: rows[0].cnt, fcm: !!global.fcmAdmin });
  } catch (err) {
    res.json({ status: 'ok', service: 'Q8Sebha API', db_error: err.message });
  }
});
app.use((_, res) => res.status(404).json({ success: false, message: 'المسار غير موجود' }));
app.use((err, req, res, next) => {
  console.error('[ERROR]', err.message);
  res.status(500).json({ success: false, message: 'خطأ في الخادم' });
});

// ─── helper: إرسال إشعار + FCM لمستخدم ──────────────────────────────────
async function notifyUser(userId, type, title, body, icon, data = {}) {
  try {
    await db.query(
      `INSERT INTO notifications (user_id,type,title,body,icon,data) VALUES ($1,$2,$3,$4,$5,$6)`,
      [userId, type, title, body, icon, JSON.stringify(data)]);
    if (global.fcmAdmin) {
      const { rows } = await db.query('SELECT device_token FROM users WHERE id=$1', [userId]);
      const dt = rows[0]?.device_token;
      if (dt) await global.fcmAdmin.messaging().send({
        token: dt,
        notification: { title, body },
        data: { type, ...Object.fromEntries(Object.entries(data).map(([k,v]) => [k, String(v)])) },
        apns: { payload: { aps: { sound: 'default', badge: 1 } } },
      }).catch(() => {});
    }
    const ws = global.wsClients?.[String(userId)];
    if (ws?.readyState === 1) ws.send(JSON.stringify({ type, title, body, ...data }));
  } catch (_) {}
}
global.notifyUser = notifyUser;

// ─── Cron: إنهاء المزادات + تنبيه 5 دقائق + auto-bid ────────────────────
setInterval(async () => {
  try {
    // 1) إنهاء المزادات المنتهية مع مراعاة السعر الاحتياطي
    const { rows: ended } = await db.query(`
      UPDATE auctions SET
        status = CASE
          WHEN reserve_price IS NOT NULL AND current_price < reserve_price THEN 'reserve_not_met'
          WHEN current_bidder_id IS NOT NULL THEN 'ended'
          ELSE 'no_bids'
        END,
        winner_id = CASE
          WHEN reserve_price IS NOT NULL AND current_price < reserve_price THEN NULL
          WHEN current_bidder_id IS NOT NULL THEN current_bidder_id
          ELSE NULL
        END,
        final_price = CASE
          WHEN reserve_price IS NOT NULL AND current_price < reserve_price THEN NULL
          WHEN current_bidder_id IS NOT NULL THEN current_price
          ELSE NULL
        END
      WHERE status = 'active' AND ends_at <= NOW()
      RETURNING id, title, status, winner_id, final_price
    `);

    for (const auction of ended) {
      if (auction.winner_id && auction.status === 'ended') {
        await notifyUser(auction.winner_id, 'auction_won', 'مبروك! فزت بالمزاد 🏆',
          `فزت بـ "${auction.title}" بسعر ${auction.final_price} د.ك`, '🏆',
          { auction_id: auction.id });
      }
      // WebSocket broadcast انتهاء
      const wsMsg = JSON.stringify({ type: 'auction_ended', auction_id: auction.id, status: auction.status });
      if (global.wsClients) Object.values(global.wsClients).forEach(ws => { try { ws.send(wsMsg); } catch(_){} });
    }

    // 2) تنبيه آخر 5 دقائق — مرة واحدة فقط لكل مزاد
    const { rows: nearEnd } = await db.query(`
      SELECT a.id, a.title, b.bidder_id
      FROM auctions a
      JOIN bids b ON b.id = (SELECT id FROM bids WHERE auction_id=a.id ORDER BY amount DESC LIMIT 1)
      WHERE a.status='active'
        AND a.ends_at BETWEEN NOW() + INTERVAL '4 minutes' AND NOW() + INTERVAL '5 minutes 30 seconds'
        AND NOT EXISTS (
          SELECT 1 FROM notifications n
          WHERE n.data::text LIKE '%"five_min_warning":' || a.id || '%'
        )
    `);
    for (const row of nearEnd) {
      // نوتيفي لكل المزايدين في هذا المزاد
      const { rows: bidders } = await db.query(
        'SELECT DISTINCT bidder_id FROM bids WHERE auction_id=$1', [row.id]);
      for (const b of bidders) {
        await notifyUser(b.bidder_id, 'auction_ending', '⏰ المزاد ينتهي قريباً!',
          `"${row.title}" — تبقّى 5 دقائق فقط`, '⏰',
          { auction_id: row.id, five_min_warning: row.id });
      }
    }

    // 3) معالجة auto-bids النشطة
    const { rows: activeBids } = await db.query(`
      SELECT ab.*, a.current_price, a.bid_increment, a.seller_id, a.status AS auction_status,
             a.title AS auction_title, a.current_bidder_id
      FROM auto_bids ab JOIN auctions a ON a.id = ab.auction_id
      WHERE ab.is_active = 1 AND a.status = 'active'
        AND a.current_bidder_id != ab.user_id
        AND a.ends_at > NOW()
    `);
    for (const ab of activeBids) {
      const nextBid = +ab.current_price + +ab.bid_increment;
      if (nextBid <= +ab.max_amount) {
        try {
          await db.query('INSERT INTO bids (auction_id,bidder_id,amount) VALUES ($1,$2,$3)',
            [ab.auction_id, ab.user_id, nextBid]);
          await db.query('UPDATE auctions SET current_price=$1, current_bidder_id=$2, bids_count=bids_count+1 WHERE id=$3',
            [nextBid, ab.user_id, ab.auction_id]);
          const msg = JSON.stringify({ type:'new_bid', auctionId: ab.auction_id, amount: nextBid, auto: true });
          if (global.wsClients) Object.values(global.wsClients).forEach(ws => { try { ws.send(msg); } catch(_){} });
        } catch(_) {}
      } else {
        // وصل للحد الأعلى — أوقف المزايدة التلقائية وأشعر المستخدم
        await db.query('UPDATE auto_bids SET is_active=0 WHERE id=$1', [ab.id]);
        await notifyUser(ab.user_id, 'auto_bid_limit', '⚠️ وصلت للحد الأعلى',
          `المزايدة التلقائية في "${ab.auction_title}" وصلت لحدها — زِد المبلغ للاستمرار`, '⚠️',
          { auction_id: ab.auction_id });
      }
    }

  } catch (err) { console.error('[cron]', err.message); }
}, 60 * 1000);

// ─── Start ────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`\n  ╔══════════════════════════════════╗`);
  console.log(`  ║  🕌  Q8Sebha API Ready           ║`);
  console.log(`  ║  🌐  http://localhost:${PORT}       ║`);
  console.log(`  ╚══════════════════════════════════╝\n`);
});
