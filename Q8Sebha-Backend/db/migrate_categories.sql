-- ─── تحديث جدول الفئات — نظام هرمي مع فئات فرعية ───────────────────────────
-- تشغيل هذا الملف مرة واحدة فقط في Supabase SQL Editor

-- 1. إضافة أعمدة جديدة
ALTER TABLE categories ADD COLUMN IF NOT EXISTS parent_id INTEGER REFERENCES categories(id);
ALTER TABLE categories ADD COLUMN IF NOT EXISTS name_en TEXT;

-- 2. إدراج الفئات الرئيسية
INSERT INTO categories (name, name_en, parent_id) VALUES
  ('مسابيح',      'masabih',      NULL),
  ('تحف',          'tuhaf',        NULL),
  ('خواتم',        'khawatim',     NULL),
  ('صخور',         'sukhur',       NULL),
  ('أحجار كريمة', 'ahjar-karima', NULL)
ON CONFLICT DO NOTHING;

-- 3. فئات فرعية — مسابيح
INSERT INTO categories (name, name_en, parent_id)
SELECT sub.name, sub.slug, c.id
FROM categories c,
  (VALUES
    ('كهرب',      'masabih-kahrab'),
    ('مصنع',      'masabih-masna3'),
    ('فاتوران',   'masabih-faturan'),
    ('بكلايت',    'masabih-bakalait'),
    ('كاست',      'masabih-cast'),
    ('قلاليث',    'masabih-qalaliath'),
    ('صب قديم',   'masabih-sub-qadim'),
    ('تراب كهرب', 'masabih-turab'),
    ('مستكة',     'masabih-mastaka')
  ) AS sub(name, slug)
WHERE c.name_en = 'masabih'
ON CONFLICT DO NOTHING;

-- 4. فئات فرعية — أحجار كريمة
INSERT INTO categories (name, name_en, parent_id)
SELECT sub.name, sub.slug, c.id
FROM categories c,
  (VALUES
    ('ألماس',          'ahjar-almas'),
    ('ياقوت أحمر',    'ahjar-ruby'),
    ('ياقوت أزرق',    'ahjar-sapphire'),
    ('زمرد',           'ahjar-zumurrud'),
    ('جمشت',           'ahjar-jamst'),
    ('عقيق',           'ahjar-aqeeq'),
    ('فيروز',          'ahjar-fayruz'),
    ('لازورد',         'ahjar-lazurd'),
    ('توباز',          'ahjar-topaz'),
    ('زبرجد',          'ahjar-zabarjad'),
    ('مرجان',          'ahjar-marjan'),
    ('لؤلؤ',           'ahjar-lulu'),
    ('أوبال',          'ahjar-opal'),
    ('أكوامارين',      'ahjar-aquamarine'),
    ('سيترين',         'ahjar-citrine'),
    ('تنزانيت',        'ahjar-tanzanite'),
    ('تورمالين',       'ahjar-tourmaline'),
    ('حجر القمر',      'ahjar-moonstone'),
    ('كوارتز وردي',    'ahjar-rose-quartz'),
    ('كوارتز دخاني',   'ahjar-smoky-quartz'),
    ('عقيق ناري',      'ahjar-fire-agate'),
    ('كارنيليان',      'ahjar-carnelian'),
    ('أونيكس',         'ahjar-onyx'),
    ('مالاشيت',        'ahjar-malachite'),
    ('لابرادوريت',     'ahjar-labradorite'),
    ('أوبسيديان',      'ahjar-obsidian'),
    ('حجر الشمس',      'ahjar-sunstone'),
    ('كهرمان',         'ahjar-kahramaan'),
    ('رودونيت',        'ahjar-rhodonite'),
    ('هيماتيت',        'ahjar-hematite'),
    ('يشم',            'ahjar-jade'),
    ('عين النمر',      'ahjar-tiger-eye'),
    ('جارنت',          'ahjar-garnet'),
    ('أباتيت',         'ahjar-apatite'),
    ('أزوريت',         'ahjar-azurite'),
    ('كريسوكولا',      'ahjar-chrysocolla'),
    ('رودوكروزيت',     'ahjar-rhodochrosite'),
    ('حجر الدم',       'ahjar-bloodstone'),
    ('أم اللؤلؤ',      'ahjar-mother-pearl'),
    ('كوارتز روتيل',   'ahjar-rutile-quartz'),
    ('كوارتز فراولة',  'ahjar-strawberry-quartz')
  ) AS sub(name, slug)
WHERE c.name_en = 'ahjar-karima'
ON CONFLICT DO NOTHING;
