import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart';
import 'auth/login_screen.dart';
import 'home/main_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        // التوجيه بعد انتهاء Splash
        if (auth.appState == AppState.auth)  return const LoginScreen();
        if (auth.appState == AppState.main)  return const MainScreen();
        if (auth.appState == AppState.guest) return const MainScreen();

        // Splash
        return Scaffold(
          backgroundColor: AppTheme.primary,
          body: Center(
            child: Column(mainAxisAlignment:MainAxisAlignment.center, children:[
              const Text('📿', style:TextStyle(fontSize:100)),
              const SizedBox(height:16),
              const Text('Q8Sebha',
                style:TextStyle(fontFamily:'Tajawal', fontWeight:FontWeight.w700,
                                fontSize:40, color:Colors.white)),
              const SizedBox(height:8),
              Text('مسابيح وأحجار كريمة',
                style:TextStyle(fontFamily:'Tajawal', fontSize:18, color:Colors.white.withOpacity(0.85))),
              const SizedBox(height:40),
              const CircularProgressIndicator(color:Colors.white, strokeWidth:2.5),
            ]),
          ),
        );
      },
    );
  }
}
