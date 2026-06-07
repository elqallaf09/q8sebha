import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

// ─── شاشة استعادة كلمة المرور (3 مراحل) ─────────────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // 0 = أدخل الإيميل | 1 = أدخل الرمز | 2 = كلمة مرور جديدة | 3 = نجاح
  int _step = 0;
  bool _loading = false;
  String? _error;
  String _email = '';

  final _emailCtrl   = TextEditingController();
  final _codeCtrl    = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass = false;

  @override
  void dispose() {
    _emailCtrl.dispose(); _codeCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  void _setError(String e) => setState(() { _error = e; _loading = false; });
  void _clearError()       => setState(() => _error = null);

  // ─── إرسال الرمز ──────────────────────────────────────────────────────
  Future<void> _sendCode() async {
    _clearError();
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@'))
      return _setError('أدخل بريداً إلكترونياً صحيحاً');

    setState(() => _loading = true);
    try {
      await APIService.instance.forgotPassword(email);
      _email = email;
      setState(() { _step = 1; _loading = false; });
    } on APIError catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('خطأ في الاتصال، حاول مرة أخرى');
    }
  }

  // ─── إعادة إرسال الرمز ───────────────────────────────────────────────
  Future<void> _resend() async {
    _clearError();
    setState(() => _loading = true);
    try {
      await APIService.instance.forgotPassword(_email);
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إعادة إرسال الرمز',
            style: TextStyle(fontFamily: 'Tajawal'))),
      );
    } catch (_) {
      _setError('فشل إعادة الإرسال');
    }
  }

  // ─── التحقق من الرمز (ننتقل للمرحلة 2) ───────────────────────────────
  void _verifyCode() {
    _clearError();
    if (_codeCtrl.text.trim().length != 6)
      return _setError('الرمز يتكون من 6 أرقام');
    setState(() => _step = 2);
  }

  // ─── تغيير كلمة المرور ───────────────────────────────────────────────
  Future<void> _changePassword() async {
    _clearError();
    if (_passCtrl.text.length < 6) return _setError('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
    if (_passCtrl.text != _confirmCtrl.text) return _setError('كلمتا المرور غير متطابقتين');

    setState(() => _loading = true);
    try {
      await APIService.instance.resetPassword(_email, _codeCtrl.text.trim(), _passCtrl.text);
      setState(() { _step = 3; _loading = false; });
    } on APIError catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('خطأ في الاتصال، حاول مرة أخرى');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF2D2D55), Color(0xFF1A1A2E)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(children: [
              // ─── شريط الرجوع ──────────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // أيقونة
              const Text('🔐', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              const Text('استعادة كلمة المرور',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800,
                    fontSize: 24, color: Colors.white)),
              const SizedBox(height: 4),
              Text(_stepSubtitle(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Colors.white60)),
              const SizedBox(height: 24),

              // ─── مؤشر الخطوات ────────────────────────────────────────
              if (_step < 3) _StepIndicator(current: _step),
              const SizedBox(height: 24),

              // ─── البطاقة ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15),
                      blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: _buildStep(),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  String _stepSubtitle() {
    switch (_step) {
      case 0: return 'سنرسل لك رمزاً للتحقق على بريدك الإلكتروني';
      case 1: return 'أدخل الرمز المكوّن من 6 أرقام الذي أُرسل إلى\n$_email';
      case 2: return 'أدخل كلمة مرورك الجديدة';
      default: return 'تم تغيير كلمة المرور بنجاح!';
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildEmailStep();
      case 1: return _buildCodeStep();
      case 2: return _buildNewPassStep();
      default: return _buildSuccess();
    }
  }

  // ─── الخطوة 0: الإيميل ───────────────────────────────────────────────
  Widget _buildEmailStep() => Column(children: [
    Q8Field(hint: 'البريد الإلكتروني المسجّل', controller: _emailCtrl,
        icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
    if (_error != null) ...[const SizedBox(height: 8), ErrorBanner(_error!)],
    const SizedBox(height: 16),
    Q8Button(label: 'إرسال الرمز', isLoading: _loading, onTap: _sendCode),
  ]);

  // ─── الخطوة 1: الرمز ─────────────────────────────────────────────────
  Widget _buildCodeStep() => Column(children: [
    // حقول OTP 6 أرقام
    _OtpField(controller: _codeCtrl),
    if (_error != null) ...[const SizedBox(height: 8), ErrorBanner(_error!)],
    const SizedBox(height: 16),
    Q8Button(label: 'تأكيد الرمز', isLoading: _loading, onTap: _verifyCode),
    const SizedBox(height: 12),
    TextButton(
      onPressed: _loading ? null : _resend,
      child: const Text('لم يصل الرمز؟ أعد الإرسال',
        style: TextStyle(fontFamily: 'Tajawal', color: AppTheme.primary, fontSize: 13)),
    ),
  ]);

  // ─── الخطوة 2: كلمة مرور جديدة ───────────────────────────────────────
  Widget _buildNewPassStep() => Column(children: [
    Q8Field(
      hint: 'كلمة المرور الجديدة',
      controller: _passCtrl,
      icon: Icons.lock_outline,
      obscure: !_showPass,
      suffix: IconButton(
        icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
        onPressed: () => setState(() => _showPass = !_showPass),
      ),
    ),
    const SizedBox(height: 10),
    Q8Field(
      hint: 'تأكيد كلمة المرور',
      controller: _confirmCtrl,
      icon: Icons.lock_outline,
      obscure: !_showPass,
    ),
    if (_error != null) ...[const SizedBox(height: 8), ErrorBanner(_error!)],
    const SizedBox(height: 16),
    Q8Button(label: 'تغيير كلمة المرور', isLoading: _loading, onTap: _changePassword),
  ]);

  // ─── نجاح ────────────────────────────────────────────────────────────
  Widget _buildSuccess() => Column(children: [
    const SizedBox(height: 8),
    const Text('✅', style: TextStyle(fontSize: 60)),
    const SizedBox(height: 16),
    const Text('تم تغيير كلمة المرور بنجاح',
      textAlign: TextAlign.center,
      style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
          fontSize: 18, color: AppTheme.textDark)),
    const SizedBox(height: 8),
    const Text('يمكنك الآن الدخول بكلمة مرورك الجديدة',
      textAlign: TextAlign.center,
      style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: AppTheme.textMid)),
    const SizedBox(height: 24),
    Q8Button(
      label: 'العودة لتسجيل الدخول',
      onTap: () => Navigator.pop(context),
    ),
  ]);
}

// ─── مؤشر الخطوات ─────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i == current;
        final done   = i < current;
        return Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: active ? 32 : 10, height: 10,
            decoration: BoxDecoration(
              color: done
                  ? AppTheme.gold
                  : active
                      ? Colors.white
                      : Colors.white24,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          if (i < 2) const SizedBox(width: 6),
        ]);
      }),
    );
  }
}

// ─── حقل OTP ─────────────────────────────────────────────────────────────
class _OtpField extends StatelessWidget {
  final TextEditingController controller;
  const _OtpField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: 12,
        color: AppTheme.textDark,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: '• • • • • •',
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 20, letterSpacing: 8),
        filled: true,
        fillColor: const Color(0xFFF0F0EB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}
