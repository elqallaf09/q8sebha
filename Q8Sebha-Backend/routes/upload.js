const router  = require('express').Router();
const multer  = require('multer');
const https   = require('https');
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
const uploadToSupabase = (buffer, originalName, mimetype) => new Promise((resolve, reject) => {
  let ext = (originalName.split('.').pop() || 'jpg').toLowerCase();
  // HEIC/HEIF من iPhone → احفظ كـ jpg (البيانات تكون JPEG بعد image_picker compression)
  if (ext === 'heic' || ext === 'heif') { ext = 'jpg'; mimetype = 'image/jpeg'; }
  if (!['jpg','jpeg','png','webp','gif'].includes(ext)) ext = 'jpg';
  const filePath = `${Date.now()}_${Math.random().toString(36).slice(2)}.${ext}`;
  const urlObj   = new URL(`${SUPABASE_URL}/storage/v1/object/${BUCKET}/${filePath}`);

  const options = {
    hostname: urlObj.hostname,
    path:     urlObj.pathname,
    method:   'POST',
    headers:  {
      'Authorization': `Bearer ${SUPABASE_SVC_KEY}`,
      'Content-Type':  mimetype || 'image/jpeg',
      'Content-Length': buffer.length,
      'x-upsert':      'true',
    },
  };

  const req = https.request(options, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      if (res.statusCode >= 400) {
        console.error(`[upload] Supabase error ${res.statusCode}: ${data}`);
        return reject(new Error(`Supabase Storage error ${res.statusCode}: ${data}`));
      }
      const publicUrl = `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${filePath}`;
      console.log(`[upload] ✅ uploaded: ${publicUrl}`);
      resolve(publicUrl);
    });
  });
  req.on('error', reject);
  req.write(buffer);
  req.end();
});

// ─── POST /upload ─────────────────────────────────────────────────────────
router.post('/', authenticate, upload.array('images', 6), async (req, res) => {
  if (!req.files?.length)
    return res.status(400).json({ success: false, message: 'لا توجد صور' });

  if (!SUPABASE_URL || !SUPABASE_SVC_KEY) {
    console.warn('⚠️  SUPABASE_URL أو SUPABASE_SERVICE_ROLE_KEY غير مضبوط');
    return res.status(500).json({ success: false, message: 'خدمة رفع الصور غير مضبوطة' });
  }

  console.log(`[upload] ${req.files.length} file(s), sizes: ${req.files.map(f=>`${f.originalname}(${f.size}b)`).join(', ')}`);

  try {
    const urls = await Promise.all(
      req.files.map(f => uploadToSupabase(f.buffer, f.originalname, f.mimetype))
    );
    res.json({ success: true, data: { urls } });
  } catch (err) {
    console.error('[upload] ❌', err.message);
    res.status(500).json({ success: false, message: `فشل رفع الصورة: ${err.message}` });
  }
});

module.exports = router;
