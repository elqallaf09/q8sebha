import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import 'api_service.dart';

typedef BidCallback        = void Function(int auctionId, double amount, String? bidderName);
typedef NotifCallback      = void Function(String title, String body, String icon);
typedef AuctionEndCallback = void Function(int auctionId);

class WebSocketService {
  static final WebSocketService instance = WebSocketService._();
  WebSocketService._();

  WebSocketChannel? _channel;
  Timer?  _pingTimer;
  Timer?  _reconnectTimer;
  int     _retries = 0;
  String? _lastToken;

  BidCallback?        onNewBid;
  NotifCallback?      onNotification;
  AuctionEndCallback? onAuctionEnded;

  // يتصل بـ JWT token (آمن) بدل user_id
  Future<void> connectWithToken() async {
    disconnect();
    final token = await TokenStore.getAccess();
    if (token == null) return; // زائر — لا يتصل
    _lastToken = token;
    _retries   = 0;
    _connect(token);
  }

  // للزوار: اتصال بدون مصادقة لاستقبال مزادات جديدة فقط
  void connectGuest() {
    disconnect();
    _lastToken = null;
    _retries   = 0;
    _connect(null);
  }

  void _connect(String? token) {
    final wsBase = AppConfig.wsUrl;
    final uri = token != null
        ? Uri.parse('$wsBase?token=$token')
        : Uri.parse('$wsBase?guest=1');
    try {
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        _onMessage,
        onError: (_) => _scheduleReconnect(),
        onDone:  ()  => _scheduleReconnect(),
      );
      _startPing();
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _retries = 0;
  }

  void _onMessage(dynamic data) {
    try {
      final msg  = jsonDecode(data as String) as Map<String,dynamic>;
      final type = msg['type'] as String? ?? '';

      switch (type) {
        case 'new_bid':
          onNewBid?.call(
            msg['auctionId'] as int,
            (msg['amount'] as num).toDouble(),
            msg['bidderName'] as String?,
          );
        case 'auction_ended':
          final id = msg['auction_id'];
          if (id != null) onAuctionEnded?.call(id as int);
        case 'notification':
          onNotification?.call(
            msg['title'] as String? ?? '',
            msg['body']  as String? ?? '',
            msg['icon']  as String? ?? '🔔',
          );
      }
    } catch (_) {}
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      try { _channel?.sink.add('{"type":"ping"}'); } catch (_) {}
    });
  }

  void _scheduleReconnect() {
    if (_retries >= 10) return; // حد أقصى 10 محاولات
    _retries++;
    final delay = Duration(seconds: (_retries * 5).clamp(5, 60));
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () => _connect(_lastToken));
  }
}
