import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> notifications = [];
  int unreadCount = 0;
  bool isLoading = false;

  final _api = APIService.instance;

  NotificationProvider() {
    WebSocketService.instance.onNotification = (title, body, icon) {
      unreadCount++;
      notifyListeners();
    };
  }

  Future<void> fetchAll() async {
    isLoading = true; notifyListeners();
    try {
      final r = await _api.notifications();
      notifications = (r['data'] as List).map((e) => AppNotification.fromJson(e)).toList();
      unreadCount   = r['meta']?['unread'] ?? 0;
    } catch (_) {}
    isLoading = false; notifyListeners();
  }

  Future<void> markRead(int id) async {
    try {
      await _api.markRead(id);
      final idx = notifications.indexWhere((n) => n.id == id);
      if (idx != -1 && !notifications[idx].isRead) {
        notifications[idx].isRead = true;
        if (unreadCount > 0) unreadCount--;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _api.markAllRead();
      for (var n in notifications) { n.isRead = true; }
      unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }
}
