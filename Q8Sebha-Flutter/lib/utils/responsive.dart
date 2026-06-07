import 'package:flutter/material.dart';

/// ─── Responsive Helper ──────────────────────────────────────────────────────
/// استخدام:
///   R.isTablet(context)  → true إذا كان iPad أو تابلت
///   R.cols(context)      → عدد أعمدة الـ Grid (2 للموبايل، 3 للتابلت)
///   R.pad(context)       → padding الشاشة
///   R.fontScale(context) → معامل حجم الخط
class R {
  R._();

  // نقاط الكسر
  static const double _kPhone  = 600;
  static const double _kTablet = 900;

  static double width(BuildContext ctx)  => MediaQuery.of(ctx).size.width;
  static double height(BuildContext ctx) => MediaQuery.of(ctx).size.height;

  static bool isPhone(BuildContext ctx)    => width(ctx) < _kPhone;
  static bool isTablet(BuildContext ctx)   => width(ctx) >= _kPhone && width(ctx) < _kTablet;
  static bool isLargeTab(BuildContext ctx) => width(ctx) >= _kTablet;

  /// عدد أعمدة الـ Grid
  static int cols(BuildContext ctx) {
    if (isLargeTab(ctx)) return 4;
    if (isTablet(ctx))   return 3;
    return 2;
  }

  /// padding الجانبي للشاشات
  static EdgeInsets pad(BuildContext ctx) {
    final w = width(ctx);
    if (w >= _kTablet) return const EdgeInsets.symmetric(horizontal: 48);
    if (w >= _kPhone)  return const EdgeInsets.symmetric(horizontal: 24);
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  /// padding أفقي فقط كـ double
  static double hPad(BuildContext ctx) {
    final w = width(ctx);
    if (w >= _kTablet) return 48;
    if (w >= _kPhone)  return 24;
    return 16;
  }

  /// معامل حجم الخط (1.0 موبايل، 1.15 تابلت)
  static double fontScale(BuildContext ctx) {
    if (isLargeTab(ctx)) return 1.2;
    if (isTablet(ctx))   return 1.1;
    return 1.0;
  }

  /// حجم الصورة في الشاشات
  static double imageHeight(BuildContext ctx) {
    if (isLargeTab(ctx)) return 400;
    if (isTablet(ctx))   return 320;
    return 260;
  }

  /// نسبة بطاقة المنتج
  static double cardRatio(BuildContext ctx) {
    if (isLargeTab(ctx)) return 0.75;
    if (isTablet(ctx))   return 0.72;
    return 0.70;
  }

  /// حجم الأيقونة في BottomNav
  static double navIconSize(BuildContext ctx) => isTablet(ctx) ? 28 : 24;

  /// الحد الأقصى لعرض المحتوى على الشاشات الكبيرة
  static Widget constrain(Widget child, {double max = 600}) =>
      Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: max),
        child: child,
      ));
}

/// Widget مساعد يعيد build تلقائياً عند تغيير حجم الشاشة
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext ctx, bool isTablet, bool isLarge) builder;
  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => builder(
    context,
    R.isTablet(context),
    R.isLargeTab(context),
  );
}
