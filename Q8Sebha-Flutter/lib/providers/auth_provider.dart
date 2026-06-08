import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
import '../services/websocket_service.dart';

enum AppState { splash, auth, main, guest, loading }

class AuthProvider extends ChangeNotifier {
  AppState appState = AppState.splash;
  User? currentUser;
  bool isLoading = false;
  String? errorMessage;

  final _api = APIService.instance;
  final _ws  = WebSocketService.instance;

  AuthProvider() { _checkSession(); }

  Future<void> _checkSession() async {
    appState = AppState.loading;
    await Future.delayed(const Duration(milliseconds: 1200));
    final token = await TokenStore.getAccess();
    if (token == null) { appState = AppState.auth; notifyListeners(); return; }
    try {
      final r = await _api.me().timeout(const Duration(seconds: 8));
      currentUser = User.fromJson(r['data']);
      await _ws.connectWithToken();
      appState = AppState.main;
    } catch (_) {
      // السيرفر مفقود أو token منتهي → login
      appState = AppState.auth;
    }
    notifyListeners();
  }

  /// إجبار الخروج لشاشة الدخول (عند timeout)
  void forceGuest() {
    appState = AppState.auth;
    notifyListeners();
  }

  /// تسجيل الدخول بأي معرّف: هاتف، إيميل، أو اسم مستخدم
  Future<void> login(String identifier, String password, {bool saveBiometric = false}) async {
    isLoading = true; errorMessage = null; notifyListeners();
    try {
      final r = await _api.login(identifier, password);
      final d = r['data'];
      await TokenStore.save(d['access_token'], d['refresh_token']);
      currentUser = User.fromJson(d['user']);
      await _ws.connectWithToken();
      appState = AppState.main;

      // احفظ بيانات البيومتري إذا طُلب ذلك
      if (saveBiometric) {
        await BiometricService.instance.saveCredentials(identifier, password);
      }
    } on APIError catch (e) { errorMessage = e.message; }
    catch (_) { errorMessage = 'خطأ في الاتصال بالخادم'; }
    isLoading = false; notifyListeners();
  }

  Future<void> register(String name, String phone, String password,
      {String? email, String? username}) async {
    isLoading = true; errorMessage = null; notifyListeners();
    try {
      final r = await _api.register(name, phone, password,
          email: email, username: username);
      final d = r['data'];
      await TokenStore.save(d['access_token'], d['refresh_token']);
      currentUser = User.fromJson(d['user']);
      await _ws.connectWithToken();
      appState = AppState.main;
    } on APIError catch (e) { errorMessage = e.message; }
    catch (_) { errorMessage = 'خطأ في الاتصال بالخادم'; }
    isLoading = false; notifyListeners();
  }

  Future<void> loginWithGoogle(String idToken) async {
    isLoading = true; errorMessage = null; notifyListeners();
    try {
      final r = await _api.loginWithGoogle(idToken);
      final d = r['data'];
      await TokenStore.save(d['access_token'], d['refresh_token']);
      currentUser = User.fromJson(d['user']);
      await _ws.connectWithToken();
      appState = AppState.main;
    } on APIError catch (e) { errorMessage = e.message; }
    catch (_) { errorMessage = 'خطأ في تسجيل الدخول بـ Google'; }
    isLoading = false; notifyListeners();
  }

  void continueAsGuest() { appState = AppState.guest; notifyListeners(); }

  void clearError() { errorMessage = null; notifyListeners(); }

  Future<void> logout() async {
    await _api.logout();
    _ws.disconnect();
    currentUser = null;
    appState = AppState.auth;
    notifyListeners();
  }

  bool get isGuest    => appState == AppState.guest;
  bool get isLoggedIn => currentUser != null;
  bool get isAdmin    => currentUser?.isAdmin == true;
}
