import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  static const _prodBase    = 'https://q8sebha-production.up.railway.app';
  static const _devAndroid  = 'http://10.0.2.2:3000';
  static const _devWeb      = 'http://localhost:3000';

  // اجعلها false إذا تريد تشغيل السيرفر المحلي
  static const bool _useProduction = true;

  static String get baseUrl {
    if (_useProduction) return _prodBase;
    const bool isProd = bool.fromEnvironment('dart.vm.product');
    if (isProd) return _prodBase;
    if (kIsWeb)  return _devWeb;
    if (!kIsWeb && Platform.isAndroid) return _devAndroid;
    return _devWeb;
  }

  static String get apiUrl    => '$baseUrl/api';
  static String get uploadsUrl => '$baseUrl/uploads';
  static String get wsUrl {
    final ws = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://',  'ws://');
    return '$ws/ws';
  }

  /// يحوّل filename أو Cloudinary URL إلى رابط صورة كامل
  static String imageUrl(String filename) {
    if (filename.isEmpty) return '';
    // Cloudinary أو أي رابط كامل
    if (filename.startsWith('http')) return filename;
    // ملف قديم محلي (للتوافق مع البيانات القديمة)
    return '$uploadsUrl/$filename';
  }
}
