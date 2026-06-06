import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/web_socket_channel.dart';

typedef BidCallback      = void Function(int auctionId, double amount, String? bidderName);
typedef NotifCallback    = void Function(String title, String body, String icon);
typedef AuctionEndCallback = void Function(int auctionId);

class WebSocketService {
  static final WebSocketService instance = WebSocketService._();
  WebSocketService._();

  WebSocketChannel? _channel;
  Timer? _pingTimer;

  BidCallback?       onNewBid;
  NotifCallback?     onNotification;
  AuctionEndCallback? onAuctionEnded;

  void connect(int userId) {
    disconnect();
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    final uri = isProduction
        ? Uri.parse('wss://q8sebha-production.up.railway.app/ws?user_id=$userId')
        : Uri.parse('ws://${(!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : 'localhost'}:3000/ws?user_id=$userId');
    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(_onMessage, onError: (_) => _reconnect(userId), onDone: () => _reconnect(userId));
    _startPing();
  }

  void disconnect() {
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void _onMessage(dynamic data) {
    try {
      final msg = jsonDecode(data as String) as Map<String,dynamic>;
      final type = msg['type'] as String? ?? '';
      final payload = msg['payload'] as Map<String,dynamic>?;

      switch (type) {
        case 'bid_placed':
          if (payload != null && onNewBid != null) {
            onNewBid!(payload['auction_id'], (payload['amount'] as num).toDouble(), payload['bidder_name']);
          }
        case 'auction_ended':
          if (payload != null && onAuctionEnded != null) onAuctionEnded!(payload['auction_id']);
        case 'notification':
          if (payload != null && onNotification != null) {
            onNotification!(payload['title'] ?? '', payload['body'] ?? '', payload['icon'] ?? '🔔');
          }
      }
    } catch (_) {}
  }

  void _startPing() {
    _pingTimer = Timer.periodic(const Duration(seconds:25), (_) {
      _channel?.sink.add('{"type":"ping"}');
    });
  }

  void _reconnect(int userId) {
    Future.delayed(const Duration(seconds:5), () => connect(userId));
  }
}
