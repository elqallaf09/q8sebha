import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/auction_provider.dart';
import 'providers/product_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const Q8SebhaApp());
}

class Q8SebhaApp extends StatelessWidget {
  const Q8SebhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AuctionProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Q8Sebha',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        // RTL عربي
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}

// ─── ثيم التطبيق ──────────────────────────────────────────────────────────
class AppTheme {
  static const primary   = Color(0xFF1A7F4B);
  static const secondary = Color(0xFFD4AF37);
  static const bg        = Color(0xFFF8F9FA);
  static const card      = Colors.white;

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary:   primary,
      secondary: secondary,
      surface:   card,
    ),
    scaffoldBackgroundColor: bg,
    fontFamily: 'Tajawal',
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontFamily:'Tajawal', fontWeight:FontWeight.w700, fontSize:16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0F0F0),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal:16, vertical:14),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: primary,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontFamily:'Tajawal', fontWeight:FontWeight.w700, fontSize:12),
      unselectedLabelStyle: TextStyle(fontFamily:'Tajawal', fontSize:12),
    ),
  );
}
