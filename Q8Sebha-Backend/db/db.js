const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
  max: 5,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
  // مطلوب مع Supabase Transaction Pooler (PgBouncer)
  statement_timeout: 30000,
});

// تشغيل الـ schema — كل جدول لوحده
const init = async () => {
  const bcrypt = require('bcryptjs');

  const statements = [
    `CREATE TABLE IF NOT EXISTS users (
      id               SERIAL PRIMARY KEY,
      name             TEXT NOT NULL,
      phone            TEXT NOT NULL UNIQUE,
      email            TEXT UNIQUE,
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
    )`,
    `CREATE TABLE IF NOT EXISTS refresh_tokens (
      id         SERIAL PRIMARY KEY,
      user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      token      TEXT NOT NULL UNIQUE,
      expires_at TIMESTAMP NOT NULL,
      created_at TIMESTAMP DEFAULT NOW()
    )`,
    `CREATE TABLE IF NOT EXISTS categories (
      id         SERIAL PRIMARY KEY,
      name       TEXT NOT NULL,
      name_en    TEXT NOT NULL UNIQUE,
      parent_id  INTEGER REFERENCES categories(id),
      icon       TEXT DEFAULT '📿',
      sort_order INTEGER DEFAULT 0
    )`,
    `CREATE TABLE IF NOT EXISTS products (
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
    )`,
    `CREATE TABLE IF NOT EXISTS auctions (
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
    )`,
    `CREATE TABLE IF NOT EXISTS bids (
      id         SERIAL PRIMARY KEY,
      auction_id INTEGER NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
      bidder_id  INTEGER NOT NULL REFERENCES users(id),
      amount     NUMERIC NOT NULL,
      created_at TIMESTAMP DEFAULT NOW()
    )`,
    `CREATE TABLE IF NOT EXISTS orders (
      id          SERIAL PRIMARY KEY,
      buyer_id    INTEGER NOT NULL REFERENCES users(id),
      product_id  INTEGER NOT NULL REFERENCES products(id),
      quantity    INTEGER DEFAULT 1,
      total_price NUMERIC NOT NULL,
      status      TEXT DEFAULT 'pending',
      notes       TEXT,
      order_number TEXT UNIQUE,
      created_at  TIMESTAMP DEFAULT NOW()
    )`,
    `CREATE TABLE IF NOT EXISTS notifications (
      id         SERIAL PRIMARY KEY,
      user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      type       TEXT DEFAULT 'system',
      title      TEXT NOT NULL,
      body       TEXT,
      icon       TEXT DEFAULT '🔔',
      data       TEXT,
      is_read    INTEGER DEFAULT 0,
      created_at TIMESTAMP DEFAULT NOW()
    )`,
    `CREATE TABLE IF NOT EXISTS admin_logs (
      id         SERIAL PRIMARY KEY,
      admin_id   INTEGER REFERENCES users(id),
      action     TEXT NOT NULL,
      target     TEXT,
      details    TEXT,
      created_at TIMESTAMP DEFAULT NOW()
    )`,
  ];

  for (const sql of statements) {
    await pool.query(sql);
  }
  console.log('✅ الجداول جاهزة');

  // فحص إذا يوجد أدمن
  const { rows } = await pool.query("SELECT id FROM users WHERE role='admin' LIMIT 1");
  if (rows.length > 0) { console.log('✅ قاعدة البيانات جاهزة'); return; }

  const hash = await bcrypt.hash('Admin@Q8Sebha2026', 10);
  await pool.query(
    `INSERT INTO users (name,phone,email,password_hash,role,is_verified,contact_method,delivery_method)
     VALUES ($1,$2,$3,$4,'admin',1,'whatsapp','pickup')`,
    ['Q8Sebha Admin', '+96541145763', 'admin@q8sebha.com', hash]
  );

  const cats = [
    ['المسابيح','masabih',null,'📿',1],
    ['مصنع','masna3',null,'🏭',2],
    ['كهرب','kahrab',null,'🟡',3],
    ['خواتم','khawatim',null,'💍',4],
    ['أحجار كريمة','ahjar',null,'💎',5],
    ['تحف','tuhaf',null,'🏺',6],
  ];
  for (const [name,name_en,parent_id,icon,sort_order] of cats) {
    await pool.query(
      `INSERT INTO categories (name,name_en,parent_id,icon,sort_order)
       VALUES ($1,$2,$3,$4,$5) ON CONFLICT (name_en) DO NOTHING`,
      [name, name_en, parent_id, icon, sort_order]
    );
  }
  console.log('✅ قاعدة البيانات جاهزة مع البيانات الأولية');
};

init().catch(err => console.error('[DB init error]', err.message, err.stack));

module.exports = pool;
