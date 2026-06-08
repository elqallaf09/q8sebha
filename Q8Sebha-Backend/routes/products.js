const router = require('express').Router();
const db = require('../db/db');
const { authenticate, adminOnly, optionalAuth } = require('../middleware/auth');

router.get('/', optionalAuth, async (req, res) => {
  const { category, search, min_price, max_price, sort='newest', page=1, limit=20 } = req.query;
  let where = ['p.is_available=1']; const params = [];
  if (category)  {
    // دعم الفئات الفرعية: إذا كان slug يبدأ بـ parent-slug، ابحث بالـ slug المحدد
    // إذا كان slug رئيسياً، ابحث في slug هذا وكل الفئات الفرعية (slug LIKE 'parent-%')
    params.push(category);
    params.push(`${category}-%`);
    where.push(`(c.name_en=$${params.length-1} OR c.name_en LIKE $${params.length})`);
  }
  if (search)    { params.push(`%${search}%`);     where.push(`p.name ILIKE $${params.length}`); }
  if (min_price) { params.push(+min_price);         where.push(`p.price>=$${params.length}`); }
  if (max_price) { params.push(+max_price);         where.push(`p.price<=$${params.length}`); }

  const sortMap = { price_asc:'p.price ASC', price_desc:'p.price DESC', newest:'p.created_at DESC', popular:'p.sales_count DESC' };
  const orderBy = sortMap[sort]||'p.created_at DESC';
  params.push(+limit); params.push((page-1)*+limit);

  try {
    const { rows } = await db.query(
      `SELECT p.*,c.name AS category_name,c.name_en AS category_slug
       FROM products p JOIN categories c ON c.id=p.category_id
       WHERE ${where.join(' AND ')} ORDER BY ${orderBy} LIMIT $${params.length-1} OFFSET $${params.length}`, params);
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT p.*,c.name AS category_name FROM products p JOIN categories c ON c.id=p.category_id WHERE p.id=$1`, [req.params.id]);
    if (!rows.length) return res.status(404).json({ success: false, message: 'المنتج غير موجود' });
    await db.query('UPDATE products SET views_count=views_count+1 WHERE id=$1', [req.params.id]);
    res.json({ success: true, data: rows[0] });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

router.post('/', authenticate, adminOnly, async (req, res) => {
  const { category_id, name, description, price, stock=1, bead_count, bead_size_mm,
          weight_grams, material, origin_country, has_certificate=0, image_urls=[], emoji='📿', badge } = req.body;
  if (!category_id||!name||!price) return res.status(400).json({ success: false, message: 'category_id, name, price مطلوبة' });
  try {
    const { rows } = await db.query(`
      INSERT INTO products (category_id,name,description,price,stock,bead_count,bead_size_mm,
        weight_grams,material,origin_country,has_certificate,image_urls,emoji,badge,added_by)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15) RETURNING *`,
      [category_id,name,description||null,price,stock,bead_count||null,bead_size_mm||null,
       weight_grams||null,material||null,origin_country||null,has_certificate,
       JSON.stringify(image_urls),emoji,badge||null,req.user.id]);
    res.status(201).json({ success: true, data: rows[0] });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

router.put('/:id', authenticate, adminOnly, async (req, res) => {
  const allowed = ['name','description','price','stock','is_available','badge','material','weight_grams','bead_count'];
  const fields = {}; allowed.forEach(f => { if (req.body[f]!==undefined) fields[f]=req.body[f]; });
  if (!Object.keys(fields).length) return res.status(400).json({ success: false, message: 'لا بيانات للتحديث' });
  const sets = Object.keys(fields).map((k,i)=>`${k}=$${i+1}`).join(', ');
  const vals = [...Object.values(fields), req.params.id];
  try {
    await db.query(`UPDATE products SET ${sets} WHERE id=$${vals.length}`, vals);
    const { rows } = await db.query('SELECT * FROM products WHERE id=$1', [req.params.id]);
    res.json({ success: true, data: rows[0] });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

router.delete('/:id', authenticate, adminOnly, async (req, res) => {
  await db.query('UPDATE products SET is_available=0 WHERE id=$1', [req.params.id]);
  res.json({ success: true, message: 'تم إخفاء المنتج' });
});

module.exports = router;
