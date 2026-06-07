/**
 * fcm.js — إرسال إشعارات FCM عبر firebase-admin
 *
 * يتطلب: FIREBASE_SERVICE_ACCOUNT (base64 لملف service account JSON)
 *         أو FIREBASE_PROJECT_ID + FIREBASE_CLIENT_EMAIL + FIREBASE_PRIVATE_KEY
 */
const admin = require('firebase-admin');

let initialized = false;

function initFirebase() {
  if (initialized) return true;
  try {
    // الطريقة الأولى: ملف كامل بـ base64
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      const sa = JSON.parse(
        Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT, 'base64').toString('utf8')
      );
      admin.initializeApp({ credential: admin.credential.cert(sa) });
      initialized = true;
      console.log('✅ Firebase Admin initialized');
      return true;
    }
    // الطريقة الثانية: متغيرات منفصلة
    if (process.env.FIREBASE_PROJECT_ID) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId:   process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey:  (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
        }),
      });
      initialized = true;
      console.log('✅ Firebase Admin initialized (env vars)');
      return true;
    }
    console.warn('⚠️  Firebase غير مضبوط — الإشعارات معطّلة');
    return false;
  } catch (err) {
    console.error('[FCM init]', err.message);
    return false;
  }
}

/**
 * ترسل إشعار لـ device token واحد
 * @param {string} token
 * @param {string} title
 * @param {string} body
 * @param {object} data  — بيانات إضافية (اختياري)
 */
async function sendToToken(token, title, body, data = {}) {
  if (!token) return;
  if (!initFirebase()) return;
  try {
    await admin.messaging().send({
      token,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      android: { priority: 'high', notification: { channelId: 'q8sebha_channel' } },
      apns:    { payload: { aps: { sound: 'default', badge: 1 } } },
    });
  } catch (err) {
    // token منتهي — احذفه من DB
    if (err.code === 'messaging/registration-token-not-registered') {
      console.log('[FCM] expired token, should clean DB');
    } else {
      console.error('[FCM sendToToken]', err.message);
    }
  }
}

/**
 * ترسل إشعار لقائمة من الـ tokens (Multicast — حتى 500)
 */
async function sendToTokens(tokens, title, body, data = {}) {
  if (!tokens?.length) return;
  if (!initFirebase()) return;
  const valid = tokens.filter(Boolean);
  if (!valid.length) return;
  try {
    await admin.messaging().sendEachForMulticast({
      tokens: valid,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      android: { priority: 'high', notification: { channelId: 'q8sebha_channel' } },
      apns:    { payload: { aps: { sound: 'default', badge: 1 } } },
    });
  } catch (err) {
    console.error('[FCM sendToTokens]', err.message);
  }
}

module.exports = { sendToToken, sendToTokens };
