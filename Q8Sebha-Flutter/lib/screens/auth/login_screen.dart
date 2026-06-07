import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../main.dart';
import '../../widgets/common_widgets.dart';
import '../../services/biometric_service.dart';
import 'forgot_password_screen.dart';

// ─── بيانات رموز الدول ────────────────────────────────────────────────────
class CountryCode {
  final String flag, name, code;
  const CountryCode(this.flag, this.name, this.code);
}

const _countries = [
  CountryCode('🇰🇼', 'الكويت',       '+965'),
  CountryCode('🇸🇦', 'السعودية',     '+966'),
  CountryCode('🇦🇪', 'الإمارات',     '+971'),
  CountryCode('🇶🇦', 'قطر',          '+974'),
  CountryCode('🇧🇭', 'البحرين',      '+973'),
  CountryCode('🇴🇲', 'عُمان',        '+968'),
  CountryCode('🇯🇴', 'الأردن',       '+962'),
  CountryCode('🇱🇧', 'لبنان',        '+961'),
  CountryCode('🇪🇬', 'مصر',          '+20'),
  CountryCode('🇮🇶', 'العراق',       '+964'),
  CountryCode('🇾🇪', 'اليمن',        '+967'),
  CountryCode('🇸🇾', 'سوريا',        '+963'),
  CountryCode('🇵🇸', 'فلسطين',      '+970'),
  CountryCode('🇸🇩', 'السودان',      '+249'),
  CountryCode('🇲🇦', 'المغرب',       '+212'),
  CountryCode('🇹🇳', 'تونس',         '+216'),
  CountryCode('🇩🇿', 'الجزائر',      '+213'),
  CountryCode('🇱🇾', 'ليبيا',        '+218'),
  CountryCode('🇺🇸', 'أمريكا',       '+1'),
  CountryCode('🇬🇧', 'بريطانيا',     '+44'),
  CountryCode('🇩🇪', 'ألمانيا',      '+49'),
  CountryCode('🇫🇷', 'فرنسا',        '+33'),
  CountryCode('🇹🇷', 'تركيا',        '+90'),
  CountryCode('🇮🇳', 'الهند',        '+91'),
  CountryCode('🇵🇰', 'باكستان',      '+92'),
];

// ─── شاشة الدخول ─────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone      = TextEditingController();
  final _identifier = TextEditingController(); // إيميل/username في وضع الدخول
  final _password   = TextEditingController();
  final _name       = TextEditingController();
  final _email      = TextEditingController();
  final _username   = TextEditingController();

  bool _showPass  = false;
  bool _isSignup  = false;
  bool _phoneMode = true;
  String? _localError; // أخطاء التحقق المحلية

  CountryCode _country = _countries[0];

  // Face ID
  bool _biometricAvail   = false;
  bool _biometricEnabled = false;
  BiometricType? _bioType;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final avail   = await BiometricService.instance.isAvailable();
    final enabled = await BiometricService.instance.isEnabled();
    final type    = await BiometricService.instance.getType();
    if (mounted) setState(() {
      _biometricAvail   = avail;
      _biometricEnabled = enabled;
      _bioType          = type;
    });
  }

  Future<void> _loginWithBiometric(AuthProvider auth) async {
    final ok = await BiometricService.instance.authenticate();
    if (!ok) return;
    final creds = await BiometricService.instance.getSavedCredentials();
    if (creds == null) {
      setState(() => _localError = 'لا توجد بيانات محفوظة، سجّل الدخول يدوياً أولاً');
      return;
    }
    auth.login(creds['identifier']!, creds['password']!);
  }

  String get _fullPhone =>
      '${_country.code}${_phone.text.trim().replaceAll(RegExp(r'^0+'), '')}';

  @override
  void dispose() {
    _phone.dispose(); _identifier.dispose(); _password.dispose();
    _name.dispose(); _email.dispose(); _username.dispose();
    super.dispose();
  }

  void _setLocalError(String msg) => setState(() => _localError = msg);
  void _clearLocalError()         => setState(() => _localError = null);

  void _onSubmit(AuthProvider auth) {
    _clearLocalError();
    if (_isSignup) {
      // التحقق من الحقول الإجبارية
      if (_name.text.trim().isEmpty)     return _setLocalError('الاسم الكامل مطلوب');
      if (_username.text.trim().isEmpty)  return _setLocalError('اسم المستخدم مطلوب');
      if (_email.text.trim().isEmpty)     return _setLocalError('البريد الإلكتروني مطلوب');
      if (_phone.text.trim().isEmpty)     return _setLocalError('رقم الهاتف مطلوب');
      if (_password.text.length < 6)      return _setLocalError('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      auth.register(
        _name.text.trim(), _fullPhone, _password.text,
        email: _email.text.trim(), username: _username.text.trim(),
      );
    } else {
      // تسجيل الدخول
      if (_phoneMode) {
        if (_phone.text.trim().isEmpty)
          return _setLocalError('أدخل رقم هاتفك');
      } else {
        if (_identifier.text.trim().isEmpty)
          return _setLocalError('أدخل البريد الإلكتروني أو اسم المستخدم');
      }
      if (_password.text.isEmpty) return _setLocalError('أدخل كلمة المرور');

      final id = _phoneMode ? _fullPhone : _identifier.text.trim();
      final pass = _password.text;
      // هل نحفظ للبيومتري؟ (نسأل فقط إذا الجهاز يدعمه ولم يفعّله بعد)
      if (_biometricAvail && !_biometricEnabled) {
        auth.login(id, pass).then((_) {
          if (auth.isLoggedIn && mounted) _askEnableBiometric(id, pass);
        });
      } else {
        auth.login(id, pass);
      }
    }
  }

  void _askEnableBiometric(String id, String pass) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          Icon(
            _bioType == BiometricType.face
                ? Icons.face_retouching_natural
                : Icons.fingerprint,
            size: 52, color: AppTheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            _bioType == BiometricType.face
                ? 'تفعيل Face ID؟'
                : 'تفعيل بصمة الإصبع؟',
            style: const TextStyle(fontFamily: 'Tajawal',
                fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 8),
          const Text(
            'ادخل بسرعة وأمان في المرات القادمة بدون كتابة كلمة المرور',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text('لاحقاً',
                  style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await BiometricService.instance.saveCredentials(id, pass);
                  if (mounted) setState(() => _biometricEnabled = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text('تفعيل',
                  style: TextStyle(fontFamily: 'Tajawal', color: Colors.white,
                      fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // الخطأ: المحلي أولاً ثم الخادم
    final String? displayError = _localError ?? auth.errorMessage;

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
              // ─── الشعار ──────────────────────────────────────────────
              const Text('📿', style: TextStyle(fontSize: 54)),
              const SizedBox(height: 4),
              const Text('Q8Sebha',
                  style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                      fontSize: 28, color: Colors.white)),
              const Text('مسابيح وأحجار كريمة',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Colors.white60)),
              const SizedBox(height: 20),

              // ─── البطاقة ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15),
                      blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(children: [
                  // تبويب تسجيل / دخول
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      _tab('إنشاء حساب',    _isSignup,  () { auth.clearError(); setState(() { _isSignup = true;  _localError = null; }); }),
                      _tab('تسجيل الدخول', !_isSignup, () { auth.clearError(); setState(() { _isSignup = false; _localError = null; }); }),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // ─── حقول إنشاء الحساب ───────────────────────────────
                  if (_isSignup) ...[
                    Q8Field(hint: 'الاسم الكامل *',      controller: _name,     icon: Icons.person),
                    const SizedBox(height: 10),
                    Q8Field(hint: 'اسم المستخدم * (إنجليزي)', controller: _username, icon: Icons.alternate_email),
                    const SizedBox(height: 10),
                    Q8Field(hint: 'البريد الإلكتروني *', controller: _email,    icon: Icons.email,
                        keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 10),
                  ],

                  // ─── toggle الدخول: هاتف / إيميل ─────────────────────
                  if (!_isSignup) ...[
                    Row(children: [
                      _modeBtn('رقم الهاتف',            _phoneMode,  () => setState(() { _phoneMode = true;  _localError = null; })),
                      const SizedBox(width: 8),
                      _modeBtn('إيميل / اسم المستخدم', !_phoneMode, () => setState(() { _phoneMode = false; _localError = null; })),
                    ]),
                    const SizedBox(height: 10),
                  ],

                  // ─── حقل الهاتف مع رمز الدولة ────────────────────────
                  if (_isSignup || _phoneMode)
                    _PhoneField(
                      country: _country,
                      controller: _phone,
                      onPickCountry: () => _showCountryPicker(context),
                    ),

                  // ─── حقل الإيميل / اسم المستخدم (دخول فقط) ───────────
                  if (!_isSignup && !_phoneMode)
                    Q8Field(
                      hint: 'البريد الإلكتروني أو اسم المستخدم',
                      controller: _identifier,
                      icon: Icons.alternate_email,
                      keyboard: TextInputType.emailAddress,
                    ),

                  const SizedBox(height: 10),

                  // ─── كلمة المرور ──────────────────────────────────────
                  Q8Field(
                    hint: 'كلمة المرور',
                    controller: _password,
                    icon: Icons.lock,
                    obscure: !_showPass,
                    suffix: IconButton(
                      icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey),
                      onPressed: () => setState(() => _showPass = !_showPass),
                    ),
                  ),

                  // ─── بانر الخطأ ───────────────────────────────────────
                  if (displayError != null) ...[
                    const SizedBox(height: 8),
                    ErrorBanner(displayError),
                  ],
                  const SizedBox(height: 12),

                  // ─── زر الإرسال ───────────────────────────────────────
                  Q8Button(
                    label: _isSignup ? 'إنشاء الحساب' : 'تسجيل الدخول',
                    isLoading: auth.isLoading,
                    onTap: () => _onSubmit(auth),
                  ),
                  // ─── زر Face ID / بصمة (فقط في وضع الدخول) ──────────
                  if (!_isSignup && _biometricAvail && _biometricEnabled) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _loginWithBiometric(auth),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0EB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE0DED8)),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(
                            _bioType == BiometricType.face
                                ? Icons.face_retouching_natural
                                : Icons.fingerprint,
                            color: AppTheme.primary, size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _bioType == BiometricType.face
                                ? 'الدخول بواسطة Face ID'
                                : 'الدخول بواسطة البصمة',
                            style: const TextStyle(fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w700, fontSize: 14,
                                color: AppTheme.primary),
                          ),
                        ]),
                      ),
                    ),
                  ],

                  // ─── نسيت كلمة المرور (ظاهر فقط في وضع الدخول) ──────
                  if (!_isSignup) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero,
                            minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text('نسيت كلمة المرور؟',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 12,
                              color: AppTheme.primary)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 6),
                  // ─── الدخول كضيف ─────────────────────────────────────
                  TextButton.icon(
                    onPressed: auth.continueAsGuest,
                    icon: const Icon(Icons.person_outline, color: Colors.grey, size: 18),
                    label: const Text('الدخول كضيف',
                        style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey, fontSize: 13)),
                  ),
                ]),
              ),
              const SizedBox(height: 28),
              // ─── Powered by ───────────────────────────────────────────
              Text(
                'Powered by M.Q',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.25),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
      ),
    );
  }

  // ─── tab chip ─────────────────────────────────────────────────────────────
  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                  fontSize: 13, color: active ? Colors.white : Colors.grey)),
        ),
      ),
    );
  }

  // ─── mode button (phone / email) ──────────────────────────────────────────
  Widget _modeBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? AppTheme.primary : Colors.grey.shade300),
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Tajawal', fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                  color: active ? AppTheme.primary : Colors.grey)),
        ),
      ),
    );
  }

  // ─── country picker ───────────────────────────────────────────────────────
  void _showCountryPicker(BuildContext context) {
    final search = TextEditingController();
    List<CountryCode> filtered = List.from(_countries);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Column(children: [
                Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 12),
                const Text('اختر رمز الدولة',
                    style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 17)),
                const SizedBox(height: 10),
                TextField(
                  controller: search,
                  style: const TextStyle(fontFamily: 'Tajawal'),
                  decoration: InputDecoration(
                    hintText: 'بحث...', hintStyle: const TextStyle(fontFamily: 'Tajawal'),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (q) => setModal(() {
                    filtered = _countries.where((c) =>
                        c.name.contains(q) || c.code.contains(q)).toList();
                  }),
                ),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final c = filtered[i];
                  return ListTile(
                    leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                    title: Text(c.name, style: const TextStyle(fontFamily: 'Tajawal')),
                    trailing: Text(c.code,
                        style: const TextStyle(fontFamily: 'Tajawal', color: AppTheme.primary,
                            fontWeight: FontWeight.w700)),
                    onTap: () {
                      setState(() => _country = c);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── حقل الهاتف مع رمز الدولة ────────────────────────────────────────────
class _PhoneField extends StatelessWidget {
  final CountryCode country;
  final TextEditingController controller;
  final VoidCallback onPickCountry;

  const _PhoneField({
    required this.country,
    required this.controller,
    required this.onPickCountry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0EB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: onPickCountry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(country.flag, style: const TextStyle(fontSize: 19)),
              const SizedBox(width: 3),
              Text(country.code,
                  style: const TextStyle(fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.primary)),
              const Icon(Icons.arrow_drop_down, color: AppTheme.primary, size: 16),
            ]),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'XXXXXXXX',
              hintStyle: TextStyle(color: Colors.grey),
              filled: false, border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            ),
          ),
        ),
      ]),
    );
  }
}
