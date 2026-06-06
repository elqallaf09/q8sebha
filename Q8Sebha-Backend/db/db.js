const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// تشغيل الـ schema وإضافة البيانات الأولية
const init = async () => {
  const fs     = require('fs');
  const path   = require('path');
  const bcrypt = require('bcryptjs');

  const schema = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
  await pool.query(schema);

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

init().catch(err => console.error('[DB init error]', err.message));

module.exports = pool;
