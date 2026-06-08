import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import '../main.dart';
import '../screens/orders/orders_screen.dart';

/// معالج الإشعارات في الخلفية (خارج الكلاس)
@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage msg) async {
  await Firebase.initializeApp();
  FCMService._showLocal(msg);
}

class FCMService {
  static final FCMService instance = FCMService._();
  FCMService._();

  final _fcm   = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'liger_channel', 'Liger Mesbah',
    description: 'إشعارات المزادات والمنتجات',
    importance: Importance.high,
  );

  // ─── تهيئة ────────────────────────────────────────────────────────────
  Future<void> init() async {
    // صلاحيات iOS
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // إعداد القناة (Android)
    await _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // إعداد Local Notifications
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    // معالج الخلفية
    FirebaseMessaging.onBackgroundMessage(_bgHandler);

    // إشعار وصل والتطبيق مفتوح — عرض محلي
    FirebaseMessaging.onMessage.listen(_showLocal);

    // الضغط على إشعار والتطبيق في الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // الضغط على إشعار والتطبيق كان مغلقاً
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      // نأخر قليلاً حتى يجهز الـ navigator
      Future.delayed(const Duration(milliseconds: 500), () => _handleTap(initial));
    }

    // حفظ token في الـ backend
    final token = await _fcm.getToken();
    if (token != null) await _saveToken(token);

    // تحديث token عند التجديد
    _fcm.onTokenRefresh.listen(_saveToken);
  }

  // ─── التنقل عند الضغط على الإشعار ───────────────────────────────────────
  static void _handleTap(RemoteMessage msg) {
    final type = msg.data['type'];
    final nav  = navigatorKey.currentState;
    if (nav == null) return;

    if (type == 'order_status') {
      nav.push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
    }
    // يمكن إضافة أنواع أخرى هنا (auction, payment, إلخ)
  }

  // ─── عرض إشعار محلي ──────────────────────────────────────────────────
  static void _showLocal(RemoteMessage msg) {
    final n = msg.notification;
    if (n == null) return;
    FCMService.instance._local.show(
      msg.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id, _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
        ),
      ),
    );
  }

  // ─── حفظ token في الـ backend ─────────────────────────────────────────
  Future<void> _saveToken(String token) async {
    try {
      await APIService.instance.request(
        'PATCH', '/auth/device-token',
        body: {'device_token': token},
      );
    } catch (_) {}
  }

  // ─── الحصول على الـ token ─────────────────────────────────────────────
  Future<String?> getToken() => _fcm.getToken();
}
