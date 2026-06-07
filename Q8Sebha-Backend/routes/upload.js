const router      = require('express').Router();
const multer      = require('multer');
const cloudinary  = require('cloudinary').v2;
const streamifier = require('streamifier');
const { authenticate } = require('../middleware/auth');

// ─── إعداد Cloudinary ────────────────────────────────────────────────────
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key:    process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure:     true,
});

// multer في الذاكرة (لا disk — مهم لـ Railway)
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

// رفع ملف واحد على Cloudinary
const uploadToCloud = (buffer) =>
  new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: 'q8sebha',
        transformation: [{ quality: 'auto:good', fetch_format: 'auto', width: 1200, crop: 'limit' }],
      },
      (err, result) => err ? reject(err) : resolve(result.secure_url)
    );
    streamifier.createReadStream(buffer).pipe(stream);
  });

// ─── POST /upload ─────────────────────────────────────────────────────────
router.post('/', authenticate, upload.array('images', 6), async (req, res) => {
  if (!req.files?.length)
    return res.status(400).json({ success: false, message: 'لا توجد صور' });

  // إذا Cloudinary غير مضبوط — fallback للـ URL المحلي (dev mode)
  if (!process.env.CLOUDINARY_CLOUD_NAME) {
    console.warn('⚠️  CLOUDINARY غير مضبوط — استخدم متغيرات البيئة');
    return res.status(500).json({ success: false, message: 'خدمة رفع الصور غير مضبوطة' });
  }

  try {
    const urls = await Promise.all(req.files.map(f => uploadToCloud(f.buffer)));
    res.json({ success: true, data: { urls } });
  } catch (err) {
    console.error('[upload cloudinary]', err.message);
    res.status(500).json({ success: false, message: 'فشل رفع الصورة، حاول مجدداً' });
  }
});

module.exports = router;
