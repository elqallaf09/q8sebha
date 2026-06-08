import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../main.dart';
import 'auth/login_screen.dart';
import 'home/main_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

// ─── يقرر: Onboarding أو Login مباشرة ────────────────────────────────────
class _AuthOrOnboarding extends StatefulWidget {
  const _AuthOrOnboarding();
  @override State<_AuthOrOnboarding> createState() => _AuthOrOnboardingState();
}

class _AuthOrOnboardingState extends State<_AuthOrOnboarding> {
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final done  = prefs.getBool('onboarding_done') ?? false;
    if (mounted) setState(() => _showOnboarding = !done);
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding == null) return const SizedBox.shrink();
    return _showOnboarding! ? const OnboardingScreen() : const LoginScreen();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fade  = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)));
    _slide = Tween<double>(begin: 30, end: 0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.8, curve: Curves.easeOut)));
    _ctrl.forward();

    // timeout — إذا لم يتحدد الـ state خلال 12 ثانية نذهب للـ login
    Future.delayed(const Duration(seconds: 12), () {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.appState == AppState.loading) {
        auth.forceGuest();
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        if (auth.appState == AppState.main)   return const MainScreen();
        if (auth.appState == AppState.guest)  return const MainScreen();
        if (auth.appState == AppState.auth)   return const _AuthOrOnboarding();
        // loading أو splash → يكمل تحميل السبلاش

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F0F1E), Color(0xFF1A1A2E), Color(0xFF252540)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // الأيقونة
                      FadeTransition(
                        opacity: _fade,
                        child: ScaleTransition(
                          scale: _scale,
                          child: Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2D2D50), Color(0xFF1A1A35)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.gold.withOpacity(0.3),
                                  blurRadius: 30, spreadRadius: 2,
                                ),
                              ],
                              border: Border.all(
                                color: AppTheme.gold.withOpacity(0.4), width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Text('📿', style: TextStyle(fontSize: 60)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // الاسم
                      FadeTransition(
                        opacity: _fade,
                        child: Transform.translate(
                          offset: Offset(0, _slide.value),
                          child: Column(children: [
                            ShaderMask(
                              shaderCallback: (b) => const LinearGradient(
                                colors: [AppTheme.goldLight, AppTheme.gold],
                              ).createShader(b),
                              child: const Text('مسابيح لايقر',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 38,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                )),
                            ),
                            const SizedBox(height: 4),
                            Text('Liger Mesbah',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.7),
                                letterSpacing: 2,
                              )),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 60),

                      // مؤشر التحميل
                      FadeTransition(
                        opacity: _fade,
                        child: SizedBox(
                          width: 40, height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.gold.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
