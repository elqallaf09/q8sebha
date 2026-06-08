import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/auction_provider.dart';
import 'providers/product_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/splash_screen.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase
  try {
    await Firebase.initializeApp();
    await FCMService.instance.init();
  } catch (e) {
    debugPrint('[Firebase] init failed: $e');
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
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
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Liger Mesbah',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
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
  // الألوان الأساسية — تصميم فاخر عصري
  static const primary      = Color(0xFF1A1A2E);   // كحلي داكن فاخر
  static const primaryLight = Color(0xFF2D2D44);
  static const gold         = Color(0xFFC9A84C);   // ذهبي دافئ
  static const goldLight    = Color(0xFFE8C96A);   // ذهبي فاتح
  static const bg           = Color(0xFFF7F6F3);   // أبيض مائل للكريمي
  static const card         = Colors.white;
  static const textDark     = Color(0xFF1A1A2E);
  static const textMid      = Color(0xFF5A5A72);
  static const textLight    = Color(0xFFAAABBB);

  // تدرج رئيسي
  static const gradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF2D2D55)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientGold = LinearGradient(
    colors: [goldLight, gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary:   primary,
      secondary: goldLight,
      surface:   card,
      surfaceContainerHighest: const Color(0xFFEEEEE8),
    ),
    scaffoldBackgroundColor: bg,
    fontFamily: 'Tajawal',

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
    ),

    // أزرار
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        textStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),

    // حقول النص
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0F0EB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: const TextStyle(
        fontFamily: 'Tajawal',
        color: textLight,
        fontSize: 14,
      ),
    ),

    // البطاقات
    cardTheme: CardThemeData(
      color: card,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),

    // NavigationBar (Material 3)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: primary.withOpacity(0.12),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primary, size: 24);
        }
        return const IconThemeData(color: textLight, size: 22);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: primary,
          );
        }
        return const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 11,
          color: textLight,
        );
      }),
      elevation: 8,
      shadowColor: Colors.black12,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFEEEEE8),
      selectedColor: primary,
      labelStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE8E8E0),
      thickness: 1,
      space: 1,
    ),
  );
}

// ─── ستايلات النصوص ───────────────────────────────────────────────────────
class AppText {
  static const heading1 = TextStyle(
    fontFamily: 'Tajawal', fontWeight: FontWeight.w800,
    fontSize: 24, color: AppTheme.textDark,
  );
  static const heading2 = TextStyle(
    fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
    fontSize: 18, color: AppTheme.textDark,
  );
  static const heading3 = TextStyle(
    fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
    fontSize: 15, color: AppTheme.textDark,
  );
  static const body = TextStyle(
    fontFamily: 'Tajawal', fontWeight: FontWeight.w400,
    fontSize: 14, color: AppTheme.textMid,
  );
  static const caption = TextStyle(
    fontFamily: 'Tajawal', fontWeight: FontWeight.w400,
    fontSize: 12, color: AppTheme.textLight,
  );
  static const price = TextStyle(
    fontFamily: 'Tajawal', fontWeight: FontWeight.w800,
    fontSize: 15, color: AppTheme.primary,
  );
  static const gold = TextStyle(
    fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
    fontSize: 14, color: AppTheme.gold,
  );
}
