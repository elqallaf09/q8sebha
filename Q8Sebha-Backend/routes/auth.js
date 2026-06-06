const router  = require('express').Router();
const bcrypt  = require('bcryptjs');
const jwt     = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const db      = require('../db/db');
const { authenticate } = require('../middleware/auth');

const JWT_SECRET  = process.env.JWT_SECRET  || 'q8sebha_jwt_secret_2026';
const JWT_REFRESH = process.env.JWT_REFRESH || 'q8sebha_refresh_2026';

const generateTokens = (userId) => ({
  access:  jwt.sign({ id: userId }, JWT_SECRET,  { expiresIn: '15m' }),
  refresh: jwt.sign({ id: userId }, JWT_REFRESH, { expiresIn: '30d' }),
});

// ─── POST /auth/register ──────────────────────────────────────────────────
router.post('/register', [
  body('name').trim().notEmpty(),
  body('phone').trim().notEmpty(),
  body('email').optional().isEmail(),
  body('password').isLength({ min: 6 }),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, errors: errors.array() });

  const { name, phone, email, password, contact_method='whatsapp', delivery_method='home', delivery_address, delivery_area } = req.body;
  try {
    const existing = await db.query('SELECT id FROM users WHERE phone=$1', [phone]);
    if (existing.rows.length) return res.status(409).json({ success: false, message: 'رقم الهاتف مستخدم مسبقاً' });

    const hash = await bcrypt.hash(password, 10);
    const { rows } = await db.query(
      `INSERT INTO users (name,phone,email,password_hash,contact_method,delivery_method,delivery_address,delivery_area)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id`,
      [name, phone, email||null, hash, contact_method, delivery_method, delivery_address||null, delivery_area||null]
    );
    const userId = rows[0].id;
    const { access, refresh } = generateTokens(userId);

    await db.query(
      `INSERT INTO refresh_tokens (user_id,token,expires_at) VALUES ($1,$2,NOW()+INTERVAL '30 days')`,
      [userId, refresh]
    );
    await db.query(
      `INSERT INTO notifications (user_id,type,title,body,icon) VALUES ($1,'system',$2,$3,'🎉')`,
      [userId, 'أهلاً بك في Q8Sebha!', 'يسعدنا انضمامك. استمتع بتصفح أجود المسابيح والأحجار الكريمة.']
    );

    const user = (await db.query('SELECT id,name,phone,email,role,contact_method,delivery_method FROM users WHERE id=$1', [userId])).rows[0];
    res.status(201).json({ success: true, data: { user, access_token: access, refresh_token: refresh } });
  } catch (err) { console.error('[register]', err.message); res.status(500).json({ success: false, message: 'خطأ في الخادم' }); }
});

// ─── POST /auth/login ─────────────────────────────────────────────────────
router.post('/login', [
  body('phone').trim().notEmpty(),
  body('password').notEmpty(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, errors: errors.array() });

  const { phone, password, device_token } = req.body;
  try {
    const { rows } = await db.query('SELECT * FROM users WHERE phone=$1', [phone]);
    const user = rows[0];
    if (!user) return res.status(401).json({ success: false, message: 'رقم الهاتف أو كلمة المرور خاطئة' });
    if (user.is_banned) return res.status(403).json({ success: false, message: 'تم حظر حسابك: ' + (user.ban_reason || 'مخالفة الشروط') });

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) return res.status(401).json({ success: false, message: 'رقم الهاتف أو كلمة المرور خاطئة' });

    if (device_token) await db.query('UPDATE users SET device_token=$1 WHERE id=$2', [device_token, user.id]);

    const { access, refresh } = generateTokens(user.id);
    await db.query(
      `INSERT INTO refresh_tokens (user_id,token,expires_at) VALUES ($1,$2,NOW()+INTERVAL '30 days')`,
      [user.id, refresh]
    );

    res.json({ success: true, data: {
      user: { id:user.id, name:user.name, phone:user.phone, email:user.email, role:user.role,
              contact_method:user.contact_method, delivery_method:user.delivery_method,
              delivery_address:user.delivery_address, delivery_area:user.delivery_area,
              total_purchases:user.total_purchases, total_wins:user.total_wins },
      access_token: access, refresh_token: refresh
    }});
  } catch (err) { console.error('[login]', err.message); res.status(500).json({ success: false, message: 'خطأ في الخادم' }); }
});

// ─── POST /auth/refresh ───────────────────────────────────────────────────
router.post('/refresh', async (req, res) => {
  const { refresh_token } = req.body;
  if (!refresh_token) return res.status(400).json({ success: false, message: 'refresh_token مطلوب' });
  try {
    const decoded = jwt.verify(refresh_token, JWT_REFRESH);
    const stored  = await db.query('SELECT * FROM refresh_tokens WHERE token=$1 AND user_id=$2', [refresh_token, decoded.id]);
    if (!stored.rows.length) return res.status(401).json({ success: false, message: 'جلسة غير صالحة' });

    const { access, refresh } = generateTokens(decoded.id);
    await db.query('DELETE FROM refresh_tokens WHERE token=$1', [refresh_token]);
    await db.query(`INSERT INTO refresh_tokens (user_id,token,expires_at) VALUES ($1,$2,NOW()+INTERVAL '30 days')`, [decoded.id, refresh]);
    res.json({ success: true, data: { access_token: access, refresh_token: refresh } });
  } catch (_) { res.status(401).json({ success: false, message: 'رمز التحديث غير صالح' }); }
});

// ─── POST /auth/logout ────────────────────────────────────────────────────
router.post('/logout', authenticate, async (req, res) => {
  const { refresh_token } = req.body;
  if (refresh_token) await db.query('DELETE FROM refresh_tokens WHERE token=$1', [refresh_token]);
  res.json({ success: true, message: 'تم تسجيل الخروج' });
});

// ─── GET /auth/me ─────────────────────────────────────────────────────────
router.get('/me', authenticate, async (req, res) => {
  const { rows } = await db.query(
    `SELECT id,name,phone,email,role,avatar_url,contact_method,delivery_method,
            delivery_address,delivery_area,total_purchases,total_wins,rating,
            total_auctions,is_verified,created_at FROM users WHERE id=$1`, [req.user.id]
  );
  res.json({ success: true, data: rows[0] });
});

// ─── PUT /auth/profile ────────────────────────────────────────────────────
router.put('/profile', authenticate, async (req, res) => {
  const allowed = ['name','contact_method','delivery_method','delivery_address','delivery_area'];
  const fields = {}; allowed.forEach(f => { if (req.body[f] !== undefined) fields[f] = req.body[f]; });
  if (!Object.keys(fields).length) return res.status(400).json({ success: false, message: 'لا بيانات للتحديث' });

  const sets = Object.keys(fields).map((k,i) => `${k}=$${i+1}`).join(', ');
  const vals = [...Object.values(fields), req.user.id];
  await db.query(`UPDATE users SET ${sets} WHERE id=$${vals.length}`, vals);

  const { rows } = await db.query('SELECT id,name,phone,email,contact_method,delivery_method,delivery_address,delivery_area FROM users WHERE id=$1', [req.user.id]);
  res.json({ success: true, data: rows[0] });
});

module.exports = router;
