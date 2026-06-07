import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {

  final _controller = PageController();
  int _page = 0;

  late final AnimationController _btnCtrl;
  late final Animation<double> _btnScale;

  static const _pages = [
    _OnboardPage(
      emoji: '📿',
      title: 'مرحباً بك في Q8Sebha',
      subtitle: 'اكتشف أجود المسابيح\nوالأحجار الكريمة من الكويت\nوحول العالم',
      color1: Color(0xFF0F0F1E),
      color2: Color(0xFF1A1A35),
      accentColor: Color(0xFFC9A84C),
    ),
    _OnboardPage(
      emoji: '🔨',
      title: 'مزادات حية',
      subtitle: 'زايد على قطع نادرة\nفي الوقت الفعلي\nوفز بأروع المسابيح',
      color1: Color(0xFF0E1A0E),
      color2: Color(0xFF1A2E1A),
      accentColor: Color(0xFF4CAF50),
    ),
    _OnboardPage(
      emoji: '🔔',
      title: 'لا تفوت شيئاً',
      subtitle: 'إشعارات فورية عند كل مزاد جديد\nوعند تجاوز مزايدتك\nكن دائماً في الصدارة',
      color1: Color(0xFF1A0E1A),
      color2: Color(0xFF2D1A35),
      accentColor: Color(0xFFAB47BC),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _btnScale = _btnCtrl;
  }

  @override
  void dispose() {
    _controller.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _done();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _pages[_page];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [p.color1, p.color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ─── زر تخطي ────────────────────────────────────────────
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _page < _pages.length - 1
                      ? TextButton(
                          onPressed: _done,
                          child: Text('تخطي',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.5),
                            )),
                        )
                      : const SizedBox(height: 40),
                ),
              ),

              // ─── الصفحات ────────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _PageContent(page: _pages[i]),
                ),
              ),

              // ─── النقاط ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) =>
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width:  _page == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _page == i
                          ? p.accentColor
                          : Colors.white.withOpacity(0.25),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ─── زر التالي / ابدأ ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: GestureDetector(
                  onTapDown:    (_) => _btnCtrl.reverse(),
                  onTapUp:      (_) { _btnCtrl.forward(); _next(); },
                  onTapCancel:  ()  => _btnCtrl.forward(),
                  child: ScaleTransition(
                    scale: _btnScale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [
                            p.accentColor,
                            p.accentColor.withOpacity(0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: p.accentColor.withOpacity(0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _page == _pages.length - 1 ? 'ابدأ الآن' : 'التالي',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── محتوى كل صفحة ────────────────────────────────────────────────────────
class _PageContent extends StatefulWidget {
  final _OnboardPage page;
  const _PageContent({required this.page});
  @override State<_PageContent> createState() => _PageContentState();
}

class _PageContentState extends State<_PageContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<double>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 40, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = widget.page;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // الإيموجي
              Transform.translate(
                offset: Offset(0, _slide.value),
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.accentColor.withOpacity(0.12),
                    border: Border.all(
                      color: p.accentColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: p.accentColor.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(p.emoji,
                      style: const TextStyle(fontSize: 68)),
                  ),
                ),
              ),

              const SizedBox(height: 44),

              // العنوان
              Transform.translate(
                offset: Offset(0, _slide.value * 0.7),
                child: ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    colors: [p.accentColor, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(b),
                  child: Text(p.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      color: Colors.white,
                      height: 1.3,
                    )),
                ),
              ),

              const SizedBox(height: 18),

              // الوصف
              Transform.translate(
                offset: Offset(0, _slide.value * 0.5),
                child: Text(p.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.65),
                    height: 1.7,
                  )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── بيانات الصفحة ─────────────────────────────────────────────────────────
class _OnboardPage {
  final String emoji, title, subtitle;
  final Color color1, color2, accentColor;
  const _OnboardPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color1,
    required this.color2,
    required this.accentColor,
  });
}
