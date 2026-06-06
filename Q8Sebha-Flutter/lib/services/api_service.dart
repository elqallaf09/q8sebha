import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';

// ─── مفاتيح التخزين ───────────────────────────────────────────────────────
class TokenStore {
  static const _access  = 'q8s_access';
  static const _refresh = 'q8s_refresh';

  static Future<String?> getAccess()  async => (await SharedPreferences.getInstance()).getString(_access);
  static Future<String?> getRefresh() async => (await SharedPreferences.getInstance()).getString(_refresh);
  static Future<void> save(String a, String r) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_access, a);
    await p.setString(_refresh, r);
  }
  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_access); await p.remove(_refresh);
  }
}

// ─── APIError ──────────────────────────────────────────────────────────────
class APIError implements Exception {
  final String message;
  APIError(this.message);
  @override String toString() => message;
}

// ─── APIService ───────────────────────────────────────────────────────────
class APIService {
  static final APIService instance = APIService._();
  APIService._();

  // يكشف الـ platform تلقائياً
  static const _prodUrl = 'https://q8sebha-production.up.railway.app/api';
  static const _devAndroid = 'http://10.0.2.2:3000/api';
  static const _devWeb = 'http://localhost:3000/api';

  static String get baseUrl {
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    if (isProduction) return _prodUrl;
    if (kIsWeb) return _devWeb;
    if (!kIsWeb && Platform.isAndroid) return _devAndroid;
    return _devWeb;
  }

  // ─── طلب عام ─────────────────────────────────────────────────────────
  Future<Map<String,dynamic>> request(
    String method, String path, {
    Map<String,dynamic>? body,
    bool auth = true,
    bool retry = true,
  }) async {
    final uri = Uri.parse(baseUrl + path);
    final headers = <String,String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await TokenStore.getAccess();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    http.Response res;
    final encoded = body != null ? jsonEncode(body) : null;
    switch (method) {
      case 'POST':   res = await http.post(uri,   headers:headers, body:encoded); break;
      case 'PUT':    res = await http.put(uri,    headers:headers, body:encoded); break;
      case 'PATCH':  res = await http.patch(uri,  headers:headers, body:encoded); break;
      case 'DELETE': res = await http.delete(uri, headers:headers); break;
      default:       res = await http.get(uri,    headers:headers);
    }

    if (res.statusCode == 401 && retry) {
      final ok = await _refreshToken();
      if (ok) return request(method, path, body:body, auth:auth, retry:false);
      throw APIError('انتهت جلستك، سجّل دخولك مجدداً');
    }

    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String,dynamic>;
    if (res.statusCode >= 400) throw APIError(json['message'] ?? 'خطأ في الخادم');
    return json;
  }

  Future<bool> _refreshToken() async {
    final rt = await TokenStore.getRefresh();
    if (rt == null) return false;
    try {
      final res = await http.post(Uri.parse('$baseUrl/auth/refresh'),
          headers:{'Content-Type':'application/json'}, body:jsonEncode({'refresh_token':rt}));
      if (res.statusCode != 200) return false;
      final j = jsonDecode(res.body);
      await TokenStore.save(j['data']['access_token'], j['data']['refresh_token']);
      return true;
    } catch (_) { return false; }
  }

  // ─── Auth ──────────────────────────────────────────────────────────────
  Future<Map<String,dynamic>> login(String phone, String password) =>
      request('POST', '/auth/login', body:{'phone':phone,'password':password}, auth:false);

  Future<Map<String,dynamic>> register(String name, String phone, String password, {String? email}) {
    final body = <String,dynamic>{'name':name,'phone':phone,'password':password};
    if (email != null && email.isNotEmpty) body['email'] = email;
    return request('POST', '/auth/register', body:body, auth:false);
  }

  Future<Map<String,dynamic>> me() => request('GET', '/auth/me');

  Future<void> logout() async {
    final rt = await TokenStore.getRefresh();
    if (rt != null) {
      try { await request('POST', '/auth/logout', body:{'refresh_token':rt}); } catch (_) {}
    }
    await TokenStore.clear();
  }

  Future<Map<String,dynamic>> updateProfile(Map<String,dynamic> data) =>
      request('PUT', '/auth/profile', body:data);

  // ─── Products ──────────────────────────────────────────────────────────
  Future<List<Product>> products({String? category, String? search, int page=1}) async {
    var q = '?page=$page';
    if (category != null) q += '&category=$category';
    if (search != null)   q += '&search=${Uri.encodeComponent(search)}';
    final r = await request('GET', '/products$q', auth:false);
    return (r['data'] as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<Product> product(int id) async {
    final r = await request('GET', '/products/$id', auth:false);
    return Product.fromJson(r['data']);
  }

  // ─── Auctions ──────────────────────────────────────────────────────────
  Future<List<Auction>> auctions({String? status, int page=1}) async {
    var q = '?page=$page';
    if (status != null) q += '&status=$status';
    final r = await request('GET', '/auctions$q', auth:false);
    return (r['data'] as List).map((e) => Auction.fromJson(e)).toList();
  }

  Future<Map<String,dynamic>> auctionDetail(int id) =>
      request('GET', '/auctions/$id', auth:false);

  Future<Map<String,dynamic>> createAuction(Map<String,dynamic> body) =>
      request('POST', '/auctions', body:body);

  Future<Map<String,dynamic>> placeBid(int auctionId, double amount) =>
      request('POST', '/auctions/$auctionId/bid', body:{'amount':amount});

  Future<void> sendPaymentLink(int auctionId, String link) =>
      request('POST', '/auctions/$auctionId/payment-link', body:{'payment_link':link});

  Future<void> reportNonPayment(int auctionId) =>
      request('POST', '/auctions/$auctionId/report');

  // ─── Orders ────────────────────────────────────────────────────────────
  Future<Map<String,dynamic>> createOrder(int productId, {String? notes}) {
    final body = <String,dynamic>{'product_id':productId};
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    return request('POST', '/orders', body:body);
  }

  Future<List<Order>> myOrders() async {
    final r = await request('GET', '/orders');
    return (r['data'] as List).map((e) => Order.fromJson(e)).toList();
  }

  // ─── Upload Images ──────────────────────────────────────────────────────
  Future<List<String>> uploadImages(List<XFile> files) async {
    final token = await TokenStore.getAccess();
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    if (token != null) req.headers['Authorization'] = 'Bearer $token';

    for (final f in files) {
      final bytes = await f.readAsBytes();
      req.files.add(http.MultipartFile.fromBytes('images', bytes, filename: f.name));
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String,dynamic>;
    if (res.statusCode >= 400) throw APIError(body['message'] ?? 'فشل رفع الصور');
    return List<String>.from(body['data']['urls']);
  }

  // ─── Notifications ──────────────────────────────────────────────────────
  Future<Map<String,dynamic>> notifications({int page=1}) =>
      request('GET', '/notifications?page=$page');

  Future<void> markRead(int id)  => request('PATCH', '/notifications/$id/read');
  Future<void> markAllRead()     => request('POST',  '/notifications/read-all');
}
