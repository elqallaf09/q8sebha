const db = require('../db/db');

// ─── إرسال إشعار داخلي + Push (APNs) ────────────────────────────────────
const sendNotification = (userId, { type, title, body, icon = '🔔', data = {}, action_url }) => {
  try {
    db.prepare(`
      INSERT INTO notifications (user_id, type, title, body, icon, data, action_url)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(userId, type, title, body, icon, JSON.stringify(data), action_url || null);

    // هنا يمكن إضافة APNs push notification
    // const user = db.prepare('SELECT device_token FROM users WHERE id=?').get(userId);
    // if (user?.device_token) pushToAPNs(user.device_token, { title, body });

    // WebSocket real-time (إذا كان المستخدم متصلاً)
    if (global.wsClients && global.wsClients[userId]) {
      global.wsClients[userId].send(JSON.stringify({ type: 'notification', payload: { title, body, icon, data } }));
    }
  } catch (err) {
    console.error('[sendNotification]', err.message);
  }
};

// ─── إشعارات نهاية المزاد للبائع والمشتري ────────────────────────────────
const sendAuctionWinNotifications = (auction, winner) => {
  // إشعار للفائز (المشتري)
  sendNotification(winner.id, {
    type:  'auction_win',
    title: '🏆 مبروك! فزت بالمزاد',
    body:  `فزت بـ "${auction.title}" بمبلغ ${auction.final_price || auction.current_price} د.ك — انتظر رابط الدفع`,
    icon:  '🏆',
    data:  {
      auction_id:    auction.id,
      seller_id:     auction.seller_id,
      amount:        auction.final_price || auction.current_price,
    },
  });

  // إشعار للبائع
  sendNotification(auction.seller_id, {
    type:  'auction_sale',
    title: '💰 تم بيع مسبحتك!',
    body:  `مسبحتك "${auction.title}" بِيعت بـ ${auction.final_price || auction.current_price} د.ك — أرسل رابط الدفع للمشتري`,
    icon:  '💰',
    data:  {
      auction_id: auction.id,
      winner_id:  winner.id,
      amount:     auction.final_price || auction.current_price,
    },
  });

  // إشعار الأدمن بالمزاد المكتمل
  const admins = db.prepare("SELECT id FROM users WHERE role='admin'").all();
  admins.forEach(admin => {
    sendNotification(admin.id, {
      type:  'system',
      title: '🔨 مزاد مكتمل',
      body:  `مزاد "${auction.title}" انتهى بـ ${auction.final_price || auction.current_price} د.ك`,
      icon:  '🔨',
      data:  { auction_id: auction.id },
    });
  });
};

module.exports = { sendNotification, sendAuctionWinNotifications };
