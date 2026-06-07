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

// ─── Cron: إنهاء المزادات كل دقيقة ──────────────────────────────────────
setInterval(async () => {
  try {
    // إنهاء المزادات المنتهية مع مراعاة السعر الاحتياطي
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
      // إشعار الفائز
      if (auction.winner_id && auction.status === 'ended') {
        await db.query(
          `INSERT INTO notifications (user_id, type, title, body, icon, data)
           VALUES ($1, 'auction_won', $2, $3, '🏆', $4)`,
          [auction.winner_id, 'مبروك! فزت بالمزاد 🎉',
           `فزت بـ "${auction.title}" بسعر ${auction.final_price} د.ك`,
           JSON.stringify({ auction_id: auction.id })]
        );
        // FCM للفائز
        if (global.fcmAdmin) {
          const { rows: wu } = await db.query('SELECT device_token FROM users WHERE id=$1', [auction.winner_id]);
          const dt = wu[0]?.device_token;
          if (dt) {
            await global.fcmAdmin.messaging().send({
              token: dt,
              notification: { title: 'مبروك! فزت بالمزاد 🏆', body: `فزت بـ "${auction.title}"` },
              data: { auction_id: String(auction.id), type: 'auction_won' },
              apns: { payload: { aps: { sound: 'default', badge: 1 } } },
            }).catch(() => {});
          }
        }
        // WebSocket
        const ws = global.wsClients[String(auction.winner_id)];
        if (ws?.readyState === 1) {
          ws.send(JSON.stringify({ type: 'auction_won', auction_id: auction.id, title: auction.title }));
        }
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
