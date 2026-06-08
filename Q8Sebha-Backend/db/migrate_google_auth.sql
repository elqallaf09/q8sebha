-- ─── إضافة دعم Google Sign-In ────────────────────────────────────────────────
-- تشغيل مرة واحدة فقط في Supabase SQL Editor

-- 1. إضافة عمود google_id
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id TEXT UNIQUE;

-- 2. إضافة عمود avatar_url (لصورة الحساب من Google)
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- 3. جعل password_hash اختياري (مستخدمو Google ما عندهم كلمة مرور)
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;
