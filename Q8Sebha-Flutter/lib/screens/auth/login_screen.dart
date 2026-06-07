import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../main.dart';
import '../../widgets/common_widgets.dart';

// ─── بيانات رموز الدول ────────────────────────────────────────────────────
class CountryCode {
  final String flag, name, code;
  const CountryCode(this.flag, this.name, this.code);
}

const _countries = [
  // ─── الخليج أولاً ───────────────────────────────────────────────────────
  CountryCode('🇰🇼', 'الكويت',        '+965'),
  CountryCode('🇸🇦', 'السعودية',       '+966'),
  CountryCode('🇦🇪', 'الإمارات',       '+971'),
  CountryCode('🇶🇦', 'قطر',           '+974'),
  CountryCode('🇧🇭', 'البحرين',        '+973'),
  CountryCode('🇴🇲', 'عُمان',          '+968'),
  // ─── الدول العربية ──────────────────────────────────────────────────────
  CountryCode('🇪🇬', 'مصر',           '+20'),
  CountryCode('🇯🇴', 'الأردن',         '+962'),
  CountryCode('🇱🇧', 'لبنان',          '+961'),
  CountryCode('🇸🇾', 'سوريا',          '+963'),
  CountryCode('🇮🇶', 'العراق',         '+964'),
  CountryCode('🇾🇪', 'اليمن',          '+967'),
  CountryCode('🇱🇾', 'ليبيا',          '+218'),
  CountryCode('🇹🇳', 'تونس',           '+216'),
  CountryCode('🇩🇿', 'الجزائر',        '+213'),
  CountryCode('🇲🇦', 'المغرب',         '+212'),
  CountryCode('🇸🇩', 'السودان',        '+249'),
  CountryCode('🇸🇴', 'الصومال',        '+252'),
  CountryCode('🇰🇲', 'جزر القمر',      '+269'),
  CountryCode('🇩🇯', 'جيبوتي',         '+253'),
  CountryCode('🇲🇷', 'موريتانيا',       '+222'),
  CountryCode('🇵🇸', 'فلسطين',         '+970'),
  // ─── دول العالم ─────────────────────────────────────────────────────────
  CountryCode('🇹🇷', 'تركيا',          '+90'),
  CountryCode('🇮🇷', 'إيران',           '+98'),
  CountryCode('🇵🇰', 'باكستان',        '+92'),
  CountryCode('🇮🇳', 'الهند',          '+91'),
  CountryCode('🇧🇩', 'بنغلاديش',       '+880'),
  CountryCode('🇵🇭', 'الفلبين',        '+63'),
  CountryCode('🇮🇩', 'إندونيسيا',      '+62'),
  CountryCode('🇲🇾', 'ماليزيا',        '+60'),
  CountryCode('🇸🇬', 'سنغافورة',       '+65'),
  CountryCode('🇨🇳', 'الصين',          '+86'),
  CountryCode('🇯🇵', 'اليابان',         '+81'),
  CountryCode('🇰🇷', 'كوريا الجنوبية', '+82'),
  CountryCode('🇷🇺', 'روسيا',          '+7'),
  CountryCode('🇩🇪', 'ألمانيا',        '+49'),
  CountryCode('🇫🇷', 'فرنسا',          '+33'),
  CountryCode('🇬🇧', 'بريطانيا',       '+44'),
  CountryCode('🇮🇹', 'إيطاليا',        '+39'),
  CountryCode('🇪🇸', 'إسبانيا',        '+34'),
  CountryCode('🇳🇱', 'هولندا',         '+31'),
  CountryCode('🇧🇪', 'بلجيكا',         '+32'),
  CountryCode('🇨🇭', 'سويسرا',         '+41'),
  CountryCode('🇸🇪', 'السويد',         '+46'),
  CountryCode('🇳🇴', 'النرويج',        '+47'),
  CountryCode('🇩🇰', 'الدنمارك',       '+45'),
  CountryCode('🇦🇹', 'النمسا',         '+43'),
  CountryCode('🇵🇱', 'بولندا',         '+48'),
  CountryCode('🇺🇸', 'أمريكا',         '+1'),
  CountryCode('🇨🇦', 'كندا',           '+1'),
  CountryCode('🇦🇺', 'أستراليا',       '+61'),
  CountryCode('🇳🇿', 'نيوزيلندا',      '+64'),
  CountryCode('🇧🇷', 'البرازيل',       '+55'),
  CountryCode('🇦🇷', 'الأرجنتين',      '+54'),
  CountryCode('🇲🇽', 'المكسيك',        '+52'),
  CountryCode('🇿🇦', 'جنوب أفريقيا',   '+27'),
  CountryCode('🇳🇬', 'نيجيريا',        '+234'),
  CountryCode('🇰🇪', 'كينيا',          '+254'),
  CountryCode('🇪🇹', 'إثيوبيا',        '+251'),
  CountryCode('🇬🇭', 'غانا',           '+233'),
  CountryCode('🇺🇬', 'أوغندا',         '+256'),
  CountryCode('🇹🇿', 'تنزانيا',        '+255'),
  CountryCode('🇵🇹', 'البرتغال',       '+351'),
  CountryCode('🇬🇷', 'اليونان',        '+30'),
  CountryCode('🇷🇴', 'رومانيا',        '+40'),
  CountryCode('🇭🇺', 'المجر',          '+36'),
  CountryCode('🇨🇿', 'التشيك',         '+420'),
  CountryCode('🇸🇰', 'سلوفاكيا',       '+421'),
  CountryCode('🇭🇷', 'كرواتيا',        '+385'),
  CountryCode('🇺🇦', 'أوكرانيا',       '+380'),
  CountryCode('🇦🇿', 'أذربيجان',       '+994'),
  CountryCode('🇰🇿', 'كازاخستان',      '+7'),
  CountryCode('🇺🇿', 'أوزبكستان',      '+998'),
  CountryCode('🇦🇫', 'أفغانستان',      '+93'),
  CountryCode('🇳🇵', 'نيبال',          '+977'),
  CountryCode('🇱🇰', 'سريلانكا',       '+94'),
  CountryCode('🇲🇻', 'المالديف',       '+960'),
  CountryCode('🇹🇭', 'تايلاند',        '+66'),
  CountryCode('🇻🇳', 'فيتنام',         '+84'),
  CountryCode('🇲🇲', 'ميانمار',        '+95'),
  CountryCode('🇰🇭', 'كمبوديا',        '+855'),
  CountryCode('🇱🇦', 'لاوس',           '+856'),
  CountryCode('🇹🇼', 'تايوان',         '+886'),
  CountryCode('🇭🇰', 'هونغ كونغ',     '+852'),
  CountryCode('🇲🇴', 'ماكاو',          '+853'),
  CountryCode('🇲🇳', 'منغوليا',        '+976'),
  CountryCode('🇪🇨', 'الإكوادور',      '+593'),
  CountryCode('🇨🇴', 'كولومبيا',       '+57'),
  CountryCode('🇵🇪', 'بيرو',           '+51'),
  CountryCode('🇨🇱', 'تشيلي',          '+56'),
  CountryCode('🇺🇾', 'أوروغواي',       '+598'),
  CountryCode('🇵🇾', 'باراغواي',       '+595'),
  CountryCode('🇧🇴', 'بوليفيا',        '+591'),
  CountryCode('🇻🇪', 'فنزويلا',        '+58'),
  CountryCode('🇨🇺', 'كوبا',           '+53'),
];

// ─── شاشة الدخول ─────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone      = TextEditingController();
  final _identifier = TextEditingController(); // هاتف/إيميل/username في وضع تسجيل الدخول
  final _password   = TextEditingController();
  final _name       = TextEditingController();
  final _email      = TextEditingController();
  final _username   = TextEditingController();
  bool _showPass    = false;
  bool _isSignup    = false;
  bool _phoneMode   = true; // وضع الدخول: هاتف أم إيميل/username
  CountryCode _country = _countries[0]; // الكويت افتراضي

  String get _fullPhone => '${_country.code}${_phone.text.replaceAll(RegExp(r'^0+'), '')}';

  /// المعرّف النهائي المُرسل للسيرفر
  String get _loginIdentifier => _phoneMode ? _fullPhone : _identifier.text.trim();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF2D2D55), Color(0xFF1A1A2E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 20),
              const Text('📿', style: TextStyle(fontSize: 80)),
              const Text('Q8Sebha',
                  style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                      fontSize: 36, color: Colors.white)),
              const Text('مسابيح وأحجار كريمة',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, color: Colors.white70)),
              const SizedBox(height: 32),

              // ─── البطاقة ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1),
                      blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(children: [
                  // تبويب
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0EB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      Expanded(child: GestureDetector(
                        onTap: () => setState(() => _isSignup = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isSignup ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('إنشاء حساب', textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                                  color: _isSignup ? Colors.white : Colors.grey)),
                        ),
                      )),
                      Expanded(child: GestureDetector(
                        onTap: () => setState(() => _isSignup = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isSignup ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('تسجيل الدخول', textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                                  color: !_isSignup ? Colors.white : Colors.grey)),
                        ),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // ─── حقول التسجيل ────────────────────────────────────
                  if (_isSignup) ...[
                    Q8Field(hint: 'الاسم الكامل *', controller: _name, icon: Icons.person),
                    const SizedBox(height: 12),
                    Q8Field(hint: 'اسم المستخدم (اختياري)', controller: _username, icon: Icons.alternate_email),
                    const SizedBox(height: 12),
                    Q8Field(hint: 'البريد الإلكتروني (اختياري)', controller: _email,
                        icon: Icons.email, keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                  ],

                  // ─── toggle: هاتف / إيميل|username (في وضع الدخول) ──
                  if (!_isSignup) ...[
                    Row(children: [
                      Expanded(child: GestureDetector(
                        onTap: () => setState(() => _phoneMode = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_phoneMode ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !_phoneMode ? AppTheme.primary : Colors.grey.shade300),
                          ),
                          child: Text('إيميل / اسم المستخدم', textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Tajawal', fontSize: 12,
                              fontWeight: _phoneMode ? FontWeight.normal : FontWeight.w700,
                              color: !_phoneMode ? AppTheme.primary : Colors.grey)),
                        ),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: GestureDetector(
                        onTap: () => setState(() => _phoneMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _phoneMode ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _phoneMode ? AppTheme.primary : Colors.grey.shade300),
                          ),
                          child: Text('رقم الهاتف', textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Tajawal', fontSize: 12,
                              fontWeight: _phoneMode ? FontWeight.w700 : FontWeight.normal,
                              color: _phoneMode ? AppTheme.primary : Colors.grey)),
                        ),
                      )),
                    ]),
                    const SizedBox(height: 12),
                  ],

                  // ─── حقل الهاتف مع رمز الدولة (للهاتف) ─────────────
                  if (_isSignup || _phoneMode)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0EB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        GestureDetector(
                          onTap: () => _showCountryPicker(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(_country.flag, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 4),
                              Text(_country.code,
                                  style: const TextStyle(fontFamily: 'Tajawal',
                                      fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primary)),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_drop_down, color: AppTheme.primary, size: 18),
                            ]),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            textAlign: TextAlign.left,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'XXXXXXXX',
                              hintStyle: TextStyle(color: Colors.grey),
                              filled: false, border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                          ),
                        ),
                      ]),
                    ),

                  // ─── حقل الإيميل / اسم المستخدم (في وضع الدخول فقط) ─
                  if (!_isSignup && !_phoneMode)
                    Q8Field(
                      hint: 'البريد الإلكتروني أو اسم المستخدم',
                      controller: _identifier,
                      icon: Icons.alternate_email,
                      keyboard: TextInputType.emailAddress,
                    ),

                  const SizedBox(height: 12),

                  Q8Field(hint: 'كلمة المرور', controller: _password,
                      icon: Icons.lock, obscure: !_showPass,
                      suffix: IconButton(
                        icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey),
                        onPressed: () => setState(() => _showPass = !_showPass),
                      )),
                  const SizedBox(height: 8),

                  if (auth.errorMessage != null) ErrorBanner(auth.errorMessage!),
                  const SizedBox(height: 8),

                  Q8Button(
                    label: _isSignup ? 'إنشاء الحساب' : 'تسجيل الدخول',
                    isLoading: auth.isLoading,
                    onTap: () {
                      if (_isSignup) {
                        auth.register(_name.text, _fullPhone, _password.text,
                            email: _email.text.isEmpty ? null : _email.text,
                            username: _username.text.isEmpty ? null : _username.text);
                      } else {
                        auth.login(_loginIdentifier, _password.text);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: auth.continueAsGuest,
                    icon: const Icon(Icons.person_outline, color: Colors.grey),
                    label: const Text('الدخول كضيف',
                        style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey, fontSize: 14)),
                  ),
                ]),
              ),
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    final _searchCtrl = TextEditingController();
    List<CountryCode> _filtered = List.from(_countries);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(children: [
            // هيدر
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(children: [
                Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 14),
                const Text('اختر رمز الدولة',
                    style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 12),
                // بحث
                TextField(
                  controller: _searchCtrl,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن دولة...',
                    filled: true, fillColor: const Color(0xFFF0F0EB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                  ),
                  onChanged: (q) {
                    setModal(() {
                      _filtered = _countries.where((c) =>
                          c.name.contains(q) || c.code.contains(q)).toList();
                    });
                  },
                ),
              ]),
            ),
            const Divider(height: 1),
            // القائمة
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final c = _filtered[i];
                  final isSelected = c.code == _country.code && c.name == _country.name;
                  return ListTile(
                    onTap: () {
                      setState(() => _country = c);
                      Navigator.pop(ctx);
                    },
                    leading: Text(c.flag, style: const TextStyle(fontSize: 26)),
                    title: Text(c.name,
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                            color: isSelected ? AppTheme.primary : AppTheme.textDark)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(c.code, style: TextStyle(fontFamily: 'Tajawal', fontSize: 13,
                          color: isSelected ? AppTheme.primary : AppTheme.textLight,
                          fontWeight: FontWeight.w600)),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle, color: AppTheme.primary, size: 18),
                      ],
                    ]),
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
