const router = require('express').Router();
const db = require('../db/db');
const { authenticate, adminOnly } = require('../middleware/auth');

// ─── POST /orders — طلب منتج واحد مباشر ─────────────────────────────────
router.post('/', authenticate, async (req, res) => {
  const { product_id, notes } = req.body;
  if (!product_id) return res.status(400).json({ success: false, message: 'product_id مطلوب' });
  try {
    const product = (await db.query(
      'SELECT * FROM products WHERE id=$1 AND is_available=1', [product_id])).rows[0];
    if (!product) return res.status(404).json({ success: false, message: 'المنتج غير موجود' });
    if (product.stock < 1) return res.status(400).json({ success: false, message: 'المنتج غير متوفر' });

    const buyer = (await db.query('SELECT name,phone FROM users WHERE id=$1', [req.user.id])).rows[0];
    const orderNumber = `Q8S-${Date.now()}`;
    const { rows } = await db.query(
      `INSERT INTO orders (buyer_id,product_id,total_price,notes,order_number,buyer_name,buyer_phone)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [req.user.id, product_id, product.price, notes||null, orderNumber,
       buyer?.name, buyer?.phone]);

    await db.query('UPDATE products SET stock=stock-1 WHERE id=$1', [product_id]);

    // إشعار للأدمن
    await _notifyAdmins(db, `🛒 طلب جديد #${orderNumber}`,
      `${buyer?.name} طلب: ${product.name} — ${product.price} د.ك`);

    res.status(201).json({ success: true, data: rows[0] });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── POST /orders/from-cart — طلب من السلة ───────────────────────────────
router.post('/from-cart', authenticate, async (req, res) => {
  const { notes, delivery_address } = req.body;
  try {
    // جلب عناصر السلة
    const { rows: cartItems } = await db.query(
      `SELECT ci.*,p.name,p.price,p.emoji,p.stock
       FROM cart_items ci JOIN products p ON p.id=ci.product_id
       WHERE ci.user_id=$1`, [req.user.id]);

    if (!cartItems.length)
      return res.status(400).json({ success: false, message: 'السلة فارغة' });

    // تحقق من التوفر
    for (const item of cartItems) {
      if (item.stock < item.quantity)
        return res.status(400).json({
          success: false,
          message: `الكمية المطلوبة من "${item.name}" غير متوفرة` });
    }

    const buyer = (await db.query('SELECT name,phone FROM users WHERE id=$1', [req.user.id])).rows[0];
    const total = cartItems.reduce((s, i) => s + parseFloat(i.price) * i.quantity, 0);
    const orderNumber = `Q8S-${Date.now()}`;

    // إنشاء الطلب الرئيسي
    const { rows } = await db.query(
      `INSERT INTO orders
         (buyer_id,total_price,notes,order_number,buyer_name,buyer_phone,delivery_address,is_cart_order)
       VALUES ($1,$2,$3,$4,$5,$6,$7,1) RETURNING *`,
      [req.user.id, total.toFixed(3), notes||null, orderNumber,
       buyer?.name, buyer?.phone, delivery_address||null]);

    const orderId = rows[0].id;

    // إدراج عناصر الطلب
    for (const item of cartItems) {
      const itemTotal = (parseFloat(item.price) * item.quantity).toFixed(3);
      await db.query(
        `INSERT INTO order_items (order_id,product_id,product_name,product_emoji,quantity,unit_price,total_price)
         VALUES ($1,$2,$3,$4,$5,$6,$7)`,
        [orderId, item.product_id, item.name, item.emoji, item.quantity, item.price, itemTotal]);
      // تخفيض المخزون
      await db.query('UPDATE products SET stock=stock-$1, sales_count=sales_count+$2 WHERE id=$3',
        [item.quantity, item.quantity, item.product_id]);
    }

    // تفريغ السلة
    await db.query('DELETE FROM cart_items WHERE user_id=$1', [req.user.id]);

    // إشعار للأدمن
    const itemsSummary = cartItems.map(i=>`${i.emoji}${i.name}×${i.quantity}`).join('، ');
    await _notifyAdmins(db, `🛒 طلب جديد #${orderNumber}`,
      `${buyer?.name} — ${cartItems.length} منتج — ${total.toFixed(3)} د.ك\n${itemsSummary}`);

    // الطلب مع العناصر
    const order = await _getOrderWithItems(db, orderId);
    res.status(201).json({ success: true, data: order });
  } catch (err) {
    console.error('[orders/from-cart]', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── GET /orders — طلبات المستخدم ────────────────────────────────────────
router.get('/', authenticate, async (req, res) => {
  try {
    const { rows: orders } = await db.query(
      `SELECT o.*,p.name AS product_name,p.emoji AS product_emoji
       FROM orders o LEFT JOIN products p ON p.id=o.product_id
       WHERE o.buyer_id=$1 ORDER BY o.created_at DESC`, [req.user.id]);

    // أضف العناصر للطلبات من السلة
    for (const order of orders) {
      if (order.is_cart_order) {
        const { rows: items } = await db.query(
          'SELECT * FROM order_items WHERE order_id=$1', [order.id]);
        order.items = items;
      } else {
        order.items = [];
      }
    }
    res.json({ success: true, data: orders });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── GET /orders/admin — كل الطلبات (أدمن) ──────────────────────────────
router.get('/admin', authenticate, adminOnly, async (req, res) => {
  const { status, page=1, limit=30 } = req.query;
  let where = ''; const params = [];
  if (status) { params.push(status); where = `WHERE o.status=$1`; }
  params.push(+limit); params.push((page-1)*+limit);
  try {
    const { rows: orders } = await db.query(
      `SELECT o.*, u.name AS buyer_name_full, u.phone AS buyer_phone_full,
              p.name AS product_name, p.emoji AS product_emoji
       FROM orders o
       JOIN users u ON u.id=o.buyer_id
       LEFT JOIN products p ON p.id=o.product_id
       ${where}
       ORDER BY o.created_at DESC
       LIMIT $${params.length-1} OFFSET $${params.length}`, params);

    for (const order of orders) {
      if (order.is_cart_order) {
        const { rows: items } = await db.query(
          'SELECT * FROM order_items WHERE order_id=$1', [order.id]);
        order.items = items;
      } else {
        order.items = [];
      }
      // override buyer info from users table
      order.buyer_name  = order.buyer_name_full  || order.buyer_name;
      order.buyer_phone = order.buyer_phone_full  || order.buyer_phone;
    }

    const { rows: counts } = await db.query(
      `SELECT status, COUNT(*) FROM orders GROUP BY status`);
    const statusCounts = {};
    counts.forEach(r => statusCounts[r.status] = parseInt(r.count));

    res.json({ success: true, data: orders, meta: { statusCounts } });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── PATCH /orders/:id/status (أدمن) ─────────────────────────────────────
router.patch('/:id/status', authenticate, adminOnly, async (req, res) => {
  const { status } = req.body;
  const valid = ['pending','confirmed','processing','shipped','delivered','cancelled'];
  if (!valid.includes(status))
    return res.status(400).json({ success: false, message: 'status غير صحيح' });
  try {
    await db.query('UPDATE orders SET status=$1 WHERE id=$2', [status, req.params.id]);
    const order = (await db.query('SELECT * FROM orders WHERE id=$1', [req.params.id])).rows[0];
    if (!order) return res.status(404).json({ success: false, message: 'الطلب غير موجود' });

    // إشعار للمشتري
    const statusAr = { pending:'قيد الانتظار', confirmed:'تم التأكيد', processing:'قيد التجهيز',
                       shipped:'تم الشحن', delivered:'تم التوصيل', cancelled:'ملغي' };
    await db.query(
      `INSERT INTO notifications (user_id,type,title,body,icon)
       VALUES ($1,'order','تحديث طلبك',$2,'📦')`,
      [order.buyer_id, `طلبك #${order.order_number} أصبح: ${statusAr[status]}`]);

    res.json({ success: true, data: order });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── PATCH /orders/:id/payment-link (أدمن) ───────────────────────────────
router.patch('/:id/payment-link', authenticate, adminOnly, async (req, res) => {
  const { payment_link } = req.body;
  try {
    await db.query('UPDATE orders SET payment_link=$1 WHERE id=$2', [payment_link, req.params.id]);
    const order = (await db.query('SELECT * FROM orders WHERE id=$1', [req.params.id])).rows[0];

    await db.query(
      `INSERT INTO notifications (user_id,type,title,body,icon,data)
       VALUES ($1,'payment','رابط الدفع جاهز','اضغط لإتمام الدفع','💳',$2)`,
      [order.buyer_id, JSON.stringify({ payment_link, order_id: order.id })]);

    res.json({ success: true, data: order });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ─── Helpers ──────────────────────────────────────────────────────────────
async function _getOrderWithItems(db, orderId) {
  const order = (await db.query('SELECT * FROM orders WHERE id=$1', [orderId])).rows[0];
  if (!order) return null;
  const { rows: items } = await db.query('SELECT * FROM order_items WHERE order_id=$1', [orderId]);
  order.items = items;
  return order;
}

async function _notifyAdmins(db, title, body) {
  try {
    const { rows: admins } = await db.query(
      `SELECT id FROM users WHERE role='admin'`);
    for (const a of admins) {
      await db.query(
        `INSERT INTO notifications (user_id,type,title,body,icon)
         VALUES ($1,'order',$2,$3,'🛒')`,
        [a.id, title, body]);
    }
  } catch (_) {}
}

module.exports = router;
