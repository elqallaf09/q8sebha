const router = require('express').Router();
const multer  = require('multer');
const { authenticate } = require('../middleware/auth');

// ─── إعداد Supabase Storage ───────────────────────────────────────────────
const SUPABASE_URL     = process.env.SUPABASE_URL;
const SUPABASE_SVC_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const BUCKET           = 'products';

// multer في الذاكرة
const upload = multer({
  storage: multer.memoryStorage(),
  limits:  { fileSize: 8 * 1024 * 1024 },
  fileFilter: (_, file, cb) => {
    const ok = file.mimetype.startsWith('image/') ||
               file.mimetype === 'application/octet-stream' ||
               /\.(jpe?g|png|webp|gif|heic)$/i.test(file.originalname);
    ok ? cb(null, true) : cb(new Error('ملفات الصور فقط'));
  },
});

// رفع ملف واحد على Supabase Storage
const uploadToSupabase = async (buffer, originalName, mimetype) => {
  const ext  = (originalName.split('.').pop() || 'jpg').toLowerCase();
  const path = `${Date.now()}_${Math.random().toString(36).slice(2)}.${ext}`;
  const url  = `${SUPABASE_URL}/storage/v1/object/${BUCKET}/${path}`;

  const res = await fetch(url, {
    method:  'POST',
    headers: {
      'Authorization': `Bearer ${SUPABASE_SVC_KEY}`,
      'Content-Type':  mimetype || 'image/jpeg',
      'x-upsert':      'true',
    },
    body: buffer,
  });

  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`Supabase Storage error: ${txt}`);
  }

  return `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${path}`;
};

// ─── POST /upload ─────────────────────────────────────────────────────────
router.post('/', authenticate, upload.array('images', 6), async (req, res) => {
  if (!req.files?.length)
    return res.status(400).json({ success: false, message: 'لا توجد صور' });

  if (!SUPABASE_URL || !SUPABASE_SVC_KEY) {
    console.warn('⚠️  SUPABASE_URL أو SUPABASE_SERVICE_ROLE_KEY غير مضبوط');
    return res.status(500).json({ success: false, message: 'خدمة رفع الصور غير مضبوطة' });
  }

  try {
    const urls = await Promise.all(
      req.files.map(f => uploadToSupabase(f.buffer, f.originalname, f.mimetype))
    );
    res.json({ success: true, data: { urls } });
  } catch (err) {
    console.error('[upload supabase]', err.message);
    res.status(500).json({ success: false, message: 'فشل رفع الصورة، حاول مجدداً' });
  }
});

module.exports = router;
