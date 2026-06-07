import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// خدمة Face ID / بصمة الإصبع
class BiometricService {
  static final BiometricService instance = BiometricService._();
  BiometricService._();

  final _auth    = LocalAuthentication();
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyId   = 'biometric_identifier';
  static const _keyPass = 'biometric_password';
  static const _keyEnabled = 'biometric_enabled';

  // ─── هل الجهاز يدعم البيومتري؟ ───────────────────────────────────────
  Future<bool> isAvailable() async {
    try {
      final capable  = await _auth.isDeviceSupported();
      final enrolled = await _auth.canCheckBiometrics;
      return capable && enrolled;
    } catch (_) { return false; }
  }

  // ─── هل مفعّل من المستخدم؟ ───────────────────────────────────────────
  Future<bool> isEnabled() async {
    final val = await _storage.read(key: _keyEnabled);
    return val == 'true';
  }

  // ─── حفظ بيانات الدخول بشكل آمن ─────────────────────────────────────
  Future<void> saveCredentials(String identifier, String password) async {
    await _storage.write(key: _keyId,      value: identifier);
    await _storage.write(key: _keyPass,    value: password);
    await _storage.write(key: _keyEnabled, value: 'true');
  }

  // ─── قراءة البيانات المحفوظة ─────────────────────────────────────────
  Future<Map<String, String>?> getSavedCredentials() async {
    final id   = await _storage.read(key: _keyId);
    final pass = await _storage.read(key: _keyPass);
    if (id == null || pass == null) return null;
    return {'identifier': id, 'password': pass};
  }

  // ─── تعطيل البيومتري وحذف البيانات ──────────────────────────────────
  Future<void> disable() async {
    await _storage.delete(key: _keyId);
    await _storage.delete(key: _keyPass);
    await _storage.write(key: _keyEnabled, value: 'false');
  }

  // ─── طلب المصادقة البيومترية ─────────────────────────────────────────
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'تحقق من هويتك للدخول إلى Q8Sebha',
        options: const AuthenticationOptions(
          biometricOnly: false,  // يسمح بـ PIN احتياطياً
          stickyAuth: true,
        ),
      );
    } catch (_) { return false; }
  }

  // ─── نوع البيومتري المتاح (للأيقونة) ────────────────────────────────
  Future<BiometricType?> getType() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face))        return BiometricType.face;
      if (types.contains(BiometricType.fingerprint)) return BiometricType.fingerprint;
      if (types.contains(BiometricType.strong))      return BiometricType.strong;
      return null;
    } catch (_) { return null; }
  }
}
