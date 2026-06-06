const jwt = require('jsonwebtoken');
const db  = require('../db/db');

const JWT_SECRET = process.env.JWT_SECRET || 'q8sebha_jwt_secret_2026';

const authenticate = async (req, res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer '))
    return res.status(401).json({ success: false, message: 'توكن مطلوب' });

  try {
    const decoded = jwt.verify(header.split(' ')[1], JWT_SECRET);
    const { rows } = await db.query('SELECT id,name,phone,email,role,is_banned FROM users WHERE id=$1', [decoded.id]);
    if (!rows.length) return res.status(401).json({ success: false, message: 'المستخدم غير موجود' });
    if (rows[0].is_banned) return res.status(403).json({ success: false, message: 'تم حظر حسابك' });
    req.user = rows[0];
    next();
  } catch (_) {
    res.status(401).json({ success: false, message: 'توكن غير صالح' });
  }
};

const adminOnly = (req, res, next) => {
  if (req.user?.role !== 'admin') return res.status(403).json({ success: false, message: 'أدمن فقط' });
  next();
};

const optionalAuth = async (req, res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) return next();
  try {
    const decoded = jwt.verify(header.split(' ')[1], JWT_SECRET);
    const { rows } = await db.query('SELECT id,name,role FROM users WHERE id=$1', [decoded.id]);
    if (rows.length) req.user = rows[0];
  } catch (_) {}
  next();
};

module.exports = { authenticate, adminOnly, optionalAuth };
