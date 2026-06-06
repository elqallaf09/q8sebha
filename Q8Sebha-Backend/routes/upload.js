const router  = require('express').Router();
const multer  = require('multer');
const path    = require('path');
const fs      = require('fs');
const { authenticate } = require('../middleware/auth');

const uploadDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename:    (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
    cb(null, `${Date.now()}-${Math.random().toString(36).slice(2)}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const okMime = file.mimetype.startsWith('image/') || file.mimetype === 'application/octet-stream';
    const okExt  = /\.(jpe?g|png|webp|gif|heic)$/i.test(file.originalname);
    if (okMime || okExt) cb(null, true);
    else cb(new Error('ملفات الصور فقط'));
  },
});

router.post('/', authenticate, upload.array('images', 6), (req, res) => {
  if (!req.files?.length) return res.status(400).json({ success: false, message: 'لا توجد صور' });
  res.json({ success: true, data: { urls: req.files.map(f => f.filename) } });
});

module.exports = router;
