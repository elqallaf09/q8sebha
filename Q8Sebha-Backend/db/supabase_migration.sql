-- ══════════════════════════════════════════════════════════════════
-- Q8Sebha — Supabase Migration
-- نفّذ هذا الكود في Supabase > SQL Editor
-- ══════════════════════════════════════════════════════════════════

-- ─── 1. جدول users ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id               SERIAL PRIMARY KEY,
  name             TEXT NOT NULL,
  phone            TEXT NOT NULL UNIQUE,
  email            TEXT UNIQUE,
  username         TEXT UNIQUE,
  password_hash    TEXT NOT NULL,
  role             TEXT NOT NULL DEFAULT 'user',
  avatar_url       TEXT,
  contact_method   TEXT DEFAULT 'whatsapp',
  delivery_method  TEXT DEFAULT 'home',
  delivery_address TEXT,
  delivery_area    TEXT,
  device_token     TEXT,
  is_verified      INTEGER DEFAULT 0,
  is_banned        INTEGER DEFAULT 0,
  ban_reason       TEXT,
  total_purchases  INTEGER DEFAULT 0,
  total_wins       INTEGER DEFAULT 0,
  total_auctions   INTEGER DEFAULT 0,
  rating           NUMERIC DEFAULT 5.0,
  created_at       TIMESTAMP DEFAULT NOW()
);

-- إضافة username إذا كان الجدول موجوداً مسبقاً (للقواعد القديمة)
ALTER TABLE users ADD COLUMN IF NOT EXISTS username TEXT UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS device_token TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS delivery_address TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS delivery_area TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_purchases INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_wins INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_auctions INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS rating NUMERIC DEFAULT 5.0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_banned INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS ban_reason TEXT;
-- حقول العنوان التفصيلية
ALTER TABLE users ADD COLUMN IF NOT EXISTS delivery_country TEXT DEFAULT 'الكويت';
ALTER TABLE users ADD COLUMN IF NOT EXISTS delivery_block TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS delivery_street TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS delivery_avenue TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS delivery_house TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS delivery_apartment TEXT;

-- ─── 2. جدول refresh_tokens ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id         SERIAL PRIMARY KEY,
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token      TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ─── 3. جدول categories ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS categories (
  id         SERIAL PRIMARY KEY,
  name       TEXT NOT NULL,
  name_en    TEXT NOT NULL UNIQUE,
  parent_id  INTEGER REFERENCES categories(id),
  icon       TEXT DEFAULT '📿',
  sort_order INTEGER DEFAULT 0
);

-- ─── 4. جدول products ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id              SERIAL PRIMARY KEY,
  category_id     INTEGER NOT NULL REFERENCES categories(id),
  name            TEXT NOT NULL,
  description     TEXT,
  price           NUMERIC NOT NULL,
  stock           INTEGER DEFAULT 1,
  bead_count      INTEGER,
  bead_size_mm    NUMERIC,
  weight_grams    NUMERIC,
  material        TEXT,
  origin_country  TEXT,
  has_certificate INTEGER DEFAULT 0,
  image_urls      TEXT DEFAULT '[]',
  emoji           TEXT DEFAULT '📿',
  badge           TEXT,
  is_available    INTEGER DEFAULT 1,
  views_count     INTEGER DEFAULT 0,
  sales_count     INTEGER DEFAULT 0,
  added_by        INTEGER REFERENCES users(id),
  created_at      TIMESTAMP DEFAULT NOW()
);

-- ─── 5. جدول auctions ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS auctions (
  id                SERIAL PRIMARY KEY,
  seller_id         INTEGER NOT NULL REFERENCES users(id),
  title             TEXT NOT NULL,
  description       TEXT,
  item_type         TEXT DEFAULT 'masabih',
  bead_count        INTEGER,
  bead_size_mm      NUMERIC,
  weight_grams      NUMERIC,
  material          TEXT,
  origin_country    TEXT,
  image_urls        TEXT DEFAULT '[]',
  emoji             TEXT DEFAULT '📿',
  starting_price    NUMERIC NOT NULL,
  current_price     NUMERIC NOT NULL,
  max_price         NUMERIC,
  bid_increment     NUMERIC DEFAULT 1.0,
  reserve_price     NUMERIC,
  current_bidder_id INTEGER REFERENCES users(id),
  winner_id         INTEGER REFERENCES users(id),
  final_price       NUMERIC,
  seller_terms      TEXT,
  payment_link      TEXT,
  status            TEXT DEFAULT 'active',
  duration_minutes  INTEGER NOT NULL,
  ends_at           TIMESTAMP NOT NULL,
  listing_fee       NUMERIC DEFAULT 2.0,
  bids_count        INTEGER DEFAULT 0,
  created_at        TIMESTAMP DEFAULT NOW()
);

-- إضافة أعمدة مزادات إذا كان الجدول موجوداً مسبقاً
ALTER TABLE auctions ADD COLUMN IF NOT EXISTS reserve_price NUMERIC;
ALTER TABLE auctions ADD COLUMN IF NOT EXISTS max_price NUMERIC;
ALTER TABLE auctions ADD COLUMN IF NOT EXISTS final_price NUMERIC;
ALTER TABLE auctions ADD COLUMN IF NOT EXISTS payment_link TEXT;
ALTER TABLE auctions ADD COLUMN IF NOT EXISTS seller_terms TEXT;
ALTER TABLE auctions ADD COLUMN IF NOT EXISTS bids_count INTEGER DEFAULT 0;

-- ─── 6. جدول bids ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bids (
  id         SERIAL PRIMARY KEY,
  auction_id INTEGER NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  bidder_id  INTEGER NOT NULL REFERENCES users(id),
  amount     NUMERIC NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ─── 7. جدول orders ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
  id           SERIAL PRIMARY KEY,
  buyer_id     INTEGER NOT NULL REFERENCES users(id),
  product_id   INTEGER NOT NULL REFERENCES products(id),
  quantity     INTEGER DEFAULT 1,
  total_price  NUMERIC NOT NULL,
  status       TEXT DEFAULT 'pending',
  notes        TEXT,
  order_number TEXT UNIQUE,
  created_at   TIMESTAMP DEFAULT NOW()
);

-- ─── 8. جدول notifications ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id         SERIAL PRIMARY KEY,
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type       TEXT DEFAULT 'system',
  title      TEXT NOT NULL,
  body       TEXT,
  icon       TEXT DEFAULT '🔔',
  data       TEXT,
  is_read    INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ─── 9. جدول admin_logs ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_logs (
  id         SERIAL PRIMARY KEY,
  admin_id   INTEGER REFERENCES users(id),
  action     TEXT NOT NULL,
  target     TEXT,
  details    TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ─── 10. Indexes (أداء) ───────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_auctions_status    ON auctions(status);
CREATE INDEX IF NOT EXISTS idx_auctions_ends_at   ON auctions(ends_at);
CREATE INDEX IF NOT EXISTS idx_bids_auction_id    ON bids(auction_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_products_category  ON products(category_id);

-- ─── 11. التحقق ───────────────────────────────────────────────────
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
