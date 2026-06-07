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
    res.json({ status: 'ok', service: 'Q8Sebha API', users: rows[0].cnt });
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
    await db.query(`UPDATE auctions SET status='ended', winner_id=current_bidder_id, final_price=current_price
                    WHERE status='active' AND ends_at<=NOW() AND current_bidder_id IS NOT NULL`);
    await db.query(`UPDATE auctions SET status='ended' WHERE status='active' AND ends_at<=NOW() AND current_bidder_id IS NULL`);
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
