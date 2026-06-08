const router   = require('express').Router();
const bcrypt   = require('bcryptjs');
const jwt      = require('jsonwebtoken');
const crypto   = require('crypto');
const nodemailer = require('nodemailer');
const { body, validationResult } = require('express-validator');
const db       = require('../db/db');
const { authenticate } = require('../middleware/auth');

// ─── إعداد البريد الإلكتروني ─────────────────────────────────────────────
const mailer = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS, // App Password من Google
  },
});

async function sendResetEmail(email, code) {
  await mailer.sendMail({
    from: `"Q8Sebha 📿" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: 'رمز استعادة كلمة المرور — Q8Sebha',
    html: `
      <div dir="rtl" style="font-family:Arial;max-width:500px;margin:auto;padding:24px;border:1px solid #eee;border-radius:12px">
        <h2 style="color:#1A1A2E;text-align:center">📿 Q8Sebha</h2>
        <p style="color:#333">مرحباً،</p>
        <p style="color:#333">طلبت استعادة كلمة المرور لحسابك. استخدم الرمز التالي:</p>
        <div style="background:#1A1A2E;color:#FFD700;font-size:36px;font-weight:bold;
                    text-align:center;padding:20px;border-radius:12px;letter-spacing:8px;margin:20px 0">
          ${code}
        </div>
        <p style="color:#666;font-size:13px">• الرمز صالح لمدة <strong>10 دقائق</strong> فقط.</p>
        <p style="color:#666;font-size:13px">• إذا لم تطلب هذا، تجاهل الرسالة.</p>
        <hr style="margin:20px 0;border:none;border-top:1px solid #eee">
        <p style="color:#999;font-size:11px;text-align:center">Q8Sebha — مسابيح وأحجار كريمة</p>
      </div>
    `,
  });
}

const JWT_SECRET  = process.env.JWT_SECRET;
const JWT_REFRESH = process.env.JWT_REFRESH;
if (!JWT_SECRET || !JWT_REFRESH) {
  console.error('❌ FATAL: JWT_SECRET و JWT_REFRESH مطلوبان في .env');
  process.exit(1);
}

const generateTokens = (userId) => ({
  access:  jwt.sign({ id: userId }, JWT_SECRET,  { expiresIn: '15m' }),
  refresh: jwt.sign({ id: userId }, JWT_REFRESH, { expiresIn: '30d' }),
});

// ─── POST /auth/register ──────────────────────────────────────────────────
router.post('/register', [
  body('name').trim().notEmpty().withMessage('الاسم الكامل مطلوب'),
  body('phone').trim().notEmpty().withMessage('رقم الهاتف مطلوب'),
  body('email').trim().notEmpty().withMessage('البريد الإلكتروني مطلوب').isEmail().withMessage('البريد الإلكتروني غير صحيح'),
  body('username').trim().notEmpty().withMessage('اسم المستخدم مطلوب')
    .isLength({ min: 3 }).withMessage('اسم المستخدم يجب أن يكون 3 أحرف على الأقل')
    .matches(/^[a-zA-Z0-9_]+$/).withMessage('اسم المستخدم يحتوي فقط على حروف إنجليزية وأرقام وشرطة سفلية'),
  body('password').isLength({ min: 6 }).withMessage('كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, message: errors.array()[0].msg });

  const { name, phone, email, username, password, contact_method='whatsapp', delivery_method='home', delivery_address, delivery_area } = req.body;
  try {
    const existPhone = await db.query('SELECT id FROM users WHERE phone=$1', [phone]);
    if (existPhone.rows.length) return res.status(409).json({ success: false, message: 'رقم الهاتف مستخدم مسبقاً' });

    const existEmail = await db.query('SELECT id FROM users WHERE email=$1', [email.trim()]);
    if (existEmail.rows.length) return res.status(409).json({ success: false, message: 'البريد الإلكتروني مستخدم مسبقاً' });

    const existUser = await db.query('SELECT id FROM users WHERE username=$1', [username.trim()]);
    if (existUser.rows.length) return res.status(409).json({ success: false, message: 'اسم المستخدم مستخدم مسبقاً' });

    const hash = await bcrypt.hash(password, 10);
    const { rows } = await db.query(
      `INSERT INTO users (name,phone,email,username,password_hash,contact_method,delivery_method,delivery_address,delivery_area)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING id`,
      [name, phone, email||null, username||null, hash, contact_method, delivery_method, delivery_address||null, delivery_area||null]
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
// يقبل: phone أو email أو username في حقل واحد "identifier"
router.post('/login', [
  body('identifier').trim().notEmpty().withMessage('أدخل رقم الهاتف أو البريد أو اسم المستخدم'),
  body('password').notEmpty(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, message: errors.array()[0].msg });

  const { identifier, password, device_token } = req.body;
  try {
    // البحث بالهاتف أو الإيميل أو اسم المستخدم
    const { rows } = await db.query(
      'SELECT * FROM users WHERE phone=$1 OR email=$1 OR username=$1',
      [identifier.trim()]
    );
    const user = rows[0];
    if (!user) return res.status(401).json({ success: false, message: 'البيانات غير صحيحة، تحقق وحاول مرة أخرى' });
    if (user.is_banned) return res.status(403).json({ success: false, message: 'تم حظر حسابك: ' + (user.ban_reason || 'مخالفة الشروط') });

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) return res.status(401).json({ success: false, message: 'كلمة المرور غير صحيحة' });

    if (device_token) await db.query('UPDATE users SET device_token=$1 WHERE id=$2', [device_token, user.id]);

    const { access, refresh } = generateTokens(user.id);
    // احذف التوكنات القديمة لنفس المستخدم قبل إضافة الجديد
    await db.query('DELETE FROM refresh_tokens WHERE user_id=$1', [user.id]);
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

// ─── POST /auth/google ────────────────────────────────────────────────────
// يستقبل Google ID Token من Flutter ويُسجّل أو يدخل المستخدم
router.post('/google', async (req, res) => {
  const { id_token, device_token } = req.body;
  if (!id_token) return res.status(400).json({ success: false, message: 'id_token مطلوب' });

  try {
    const { OAuth2Client } = require('google-auth-library');
    const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
    if (!GOOGLE_CLIENT_ID) {
      return res.status(500).json({ success: false, message: 'Google Auth غير مضبوط' });
    }

    const client  = new OAuth2Client(GOOGLE_CLIENT_ID);
    const ticket  = await client.verifyIdToken({ idToken: id_token, audience: GOOGLE_CLIENT_ID });
    const payload = ticket.getPayload();
    const { email, name, sub: googleId, picture } = payload;

    if (!email) return res.status(400).json({ success: false, message: 'لا يمكن جلب الإيميل من Google' });

    // ابحث عن المستخدم بالإيميل أو google_id
    let userRow = await db.query('SELECT * FROM users WHERE email=$1 OR google_id=$2', [email, googleId]);
    let user = userRow.rows[0];

    if (!user) {
      // إنشاء حساب جديد
      const phone    = `google_${googleId}`; // placeholder
      const username = `g_${googleId.slice(-8)}`;
      const { rows } = await db.query(
        `INSERT INTO users (name,phone,email,username,google_id,avatar_url,contact_method,delivery_method)
         VALUES ($1,$2,$3,$4,$5,$6,'whatsapp','home') RETURNING *`,
        [name, phone, email, username, googleId, picture || null]
      );
      user = rows[0];
      await db.query(
        `INSERT INTO notifications (user_id,type,title,body,icon) VALUES ($1,'system',$2,$3,'🎉')`,
        [user.id, 'أهلاً بك في Q8Sebha!', 'يسعدنا انضمامك عبر Google. استمتع بتصفح أجود المسابيح.']
      );
    } else {
      // تحديث google_id إذا تسجّل مسبقاً بالإيميل
      if (!user.google_id) {
        await db.query('UPDATE users SET google_id=$1 WHERE id=$2', [googleId, user.id]);
      }
    }

    if (user.is_banned)
      return res.status(403).json({ success: false, message: 'تم حظر حسابك: ' + (user.ban_reason || 'مخالفة الشروط') });

    if (device_token) await db.query('UPDATE users SET device_token=$1 WHERE id=$2', [device_token, user.id]);

    // حذف توكنات قديمة وإنشاء جديدة
    await db.query('DELETE FROM refresh_tokens WHERE user_id=$1', [user.id]);
    const { access, refresh } = generateTokens(user.id);
    await db.query(
      `INSERT INTO refresh_tokens (user_id,token,expires_at) VALUES ($1,$2,NOW()+INTERVAL '30 days')`,
      [user.id, refresh]
    );

    res.json({ success: true, data: {
      user: { id:user.id, name:user.name, phone:user.phone, email:user.email,
              role:user.role, avatar_url:user.avatar_url,
              contact_method:user.contact_method, delivery_method:user.delivery_method },
      access_token: access, refresh_token: refresh,
    }});
  } catch (err) {
    console.error('[google-auth]', err.message);
    res.status(401).json({ success: false, message: 'Google Token غير صالح' });
  }
});

// ─── PATCH /auth/device-token ─────────────────────────────────────────────
// يحفظ FCM token للجهاز الحالي
router.patch('/device-token', authenticate, async (req, res) => {
  const { device_token } = req.body;
  if (!device_token) return res.status(400).json({ success: false, message: 'device_token مطلوب' });
  await db.query('UPDATE users SET device_token=$1 WHERE id=$2', [device_token, req.user.id]);
  res.json({ success: true });
});

// ─── PUT /auth/profile ────────────────────────────────────────────────────
router.put('/profile', authenticate, async (req, res) => {
  const allowed = ['name','contact_method','delivery_method','delivery_address','delivery_area',
    'delivery_country','delivery_block','delivery_street','delivery_avenue','delivery_house','delivery_apartment'];
  const fields = {}; allowed.forEach(f => { if (req.body[f] !== undefined) fields[f] = req.body[f]; });
  if (!Object.keys(fields).length) return res.status(400).json({ success: false, message: 'لا بيانات للتحديث' });

  const sets = Object.keys(fields).map((k,i) => `${k}=$${i+1}`).join(', ');
  const vals = [...Object.values(fields), req.user.id];
  await db.query(`UPDATE users SET ${sets} WHERE id=$${vals.length}`, vals);

  const { rows } = await db.query(
    `SELECT id,name,phone,email,username,role,contact_method,delivery_method,
            delivery_address,delivery_area,delivery_country,delivery_block,
            delivery_street,delivery_avenue,delivery_house,delivery_apartment,
            total_purchases,total_wins,total_auctions,rating,is_verified
     FROM users WHERE id=$1`, [req.user.id]);
  res.json({ success: true, data: rows[0] });
});

// ─── POST /auth/forgot-password ──────────────────────────────────────────
// يرسل رمز 6 أرقام للإيميل المسجّل
router.post('/forgot-password', [
  body('email').trim().notEmpty().isEmail().withMessage('أدخل بريداً إلكترونياً صحيحاً'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, message: errors.array()[0].msg });

  const { email } = req.body;
  try {
    const { rows } = await db.query('SELECT id FROM users WHERE email=$1', [email.trim().toLowerCase()]);
    // نرد بنجاح حتى لو الإيميل غير موجود (أمان ضد تعداد الإيميلات)
    if (!rows.length) return res.json({ success: true, message: 'إذا كان الإيميل مسجّلاً ستصلك رسالة' });

    const userId = rows[0].id;
    const code   = crypto.randomInt(100000, 999999).toString();
    const expiry = new Date(Date.now() + 10 * 60 * 1000); // 10 دقائق

    // احذف رموز سابقة لنفس المستخدم
    await db.query('DELETE FROM password_reset_tokens WHERE user_id=$1', [userId]);
    await db.query(
      'INSERT INTO password_reset_tokens (user_id, code, expires_at) VALUES ($1,$2,$3)',
      [userId, await bcrypt.hash(code, 8), expiry]
    );

    // أرسل الإيميل
    if (process.env.EMAIL_USER) {
      await sendResetEmail(email.trim(), code);
    } else {
      // وضع التطوير — اطبع الكود في السجل
      console.log(`[DEV] Reset code for ${email}: ${code}`);
    }

    res.json({ success: true, message: 'إذا كان الإيميل مسجّلاً ستصلك رسالة' });
  } catch (err) {
    console.error('[forgot-password]', err.message);
    res.status(500).json({ success: false, message: 'خطأ في الخادم' });
  }
});

// ─── POST /auth/reset-password ────────────────────────────────────────────
// يتحقق من الكود ويغيّر كلمة المرور
router.post('/reset-password', [
  body('email').trim().notEmpty().isEmail(),
  body('code').trim().notEmpty().withMessage('الرمز مطلوب'),
  body('new_password').isLength({ min: 6 }).withMessage('كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, message: errors.array()[0].msg });

  const { email, code, new_password } = req.body;
  try {
    const userRes = await db.query('SELECT id FROM users WHERE email=$1', [email.trim().toLowerCase()]);
    if (!userRes.rows.length) return res.status(400).json({ success: false, message: 'الرمز غير صحيح أو منتهي الصلاحية' });

    const userId = userRes.rows[0].id;
    const tokenRes = await db.query(
      'SELECT * FROM password_reset_tokens WHERE user_id=$1 AND expires_at > NOW()',
      [userId]
    );
    if (!tokenRes.rows.length) return res.status(400).json({ success: false, message: 'الرمز غير صحيح أو منتهي الصلاحية' });

    const valid = await bcrypt.compare(code.trim(), tokenRes.rows[0].code);
    if (!valid) return res.status(400).json({ success: false, message: 'الرمز غير صحيح أو منتهي الصلاحية' });

    const hash = await bcrypt.hash(new_password, 10);
    await db.query('UPDATE users SET password_hash=$1 WHERE id=$2', [hash, userId]);
    await db.query('DELETE FROM password_reset_tokens WHERE user_id=$1', [userId]);
    // إلغاء كل جلسات المستخدم
    await db.query('DELETE FROM refresh_tokens WHERE user_id=$1', [userId]);

    res.json({ success: true, message: 'تم تغيير كلمة المرور بنجاح' });
  } catch (err) {
    console.error('[reset-password]', err.message);
    res.status(500).json({ success: false, message: 'خطأ في الخادم' });
  }
});

module.exports = router;
