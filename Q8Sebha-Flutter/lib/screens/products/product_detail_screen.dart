import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../main.dart';
import '../../config/app_config.dart';
import '../../widgets/common_widgets.dart';
import '../cart/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  final _notes = TextEditingController();
  late final PageController _pageCtrl;
  int _currentImage = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<ProductProvider>().fetchProduct(widget.productId));
  }

  @override
  void dispose() { _notes.dispose(); _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final vm   = context.watch<ProductProvider>();
    final auth = context.watch<AuthProvider>();
    final p    = vm.selectedProduct;

    if (vm.isLoading || p == null) return const Scaffold(body: LoadingBody());

    return Scaffold(
      backgroundColor: AppTheme.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // ─── صور المنتج ─────────────────────────────────────────────
          SizedBox(
            height: 300,
            child: Stack(children: [
              p.imageUrls.isEmpty
                  ? Container(
                      color: const Color(0xFFF0EDE8),
                      child: Center(child: Text(p.emoji,
                        style: const TextStyle(fontSize: 100))))
                  : PageView.builder(
                      controller: _pageCtrl,
                      itemCount: p.imageUrls.length,
                      onPageChanged: (i) => setState(() => _currentImage = i),
                      itemBuilder: (_, i) => Image.network(
                        AppConfig.imageUrl(p.imageUrls[i]),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF0EDE8),
                          child: Center(child: Text(p.emoji,
                            style: const TextStyle(fontSize: 100)))),
                      ),
                    ),
              // تدرج سفلي
              Positioned(bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                    ),
                  ),
                )),
              // badge
              if (p.badge != null)
                Positioned(
                  top: 60, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.goldLight, AppTheme.gold]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(p.badge!,
                      style: const TextStyle(fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white)),
                  ),
                ),
              // dots للصور
              if (p.imageUrls.length > 1)
                Positioned(
                  bottom: 12, left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(p.imageUrls.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentImage == i ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentImage == i ? AppTheme.gold : Colors.white54,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
                  ),
                ),
            ]),
          ),

          // ─── المعلومات ───────────────────────────────────────────────
          Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  // اسم وسعر
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [AppTheme.goldLight, AppTheme.gold],
                          ).createShader(b),
                          child: Text(p.priceFormatted,
                            style: const TextStyle(fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w800, fontSize: 28, color: Colors.white)),
                        ),
                        Text('د.ك', style: TextStyle(fontFamily: 'Tajawal',
                          fontSize: 12, color: AppTheme.textLight)),
                      ]),
                      Expanded(
                        child: Text(p.name,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.textDark)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // مواصفات
                  if (p.beadCount != null || p.material != null || p.weightGrams != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F6F3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          const Text('المواصفات',
                            style: TextStyle(fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textDark)),
                          const SizedBox(width: 6),
                          Container(
                            width: 3, height: 20,
                            decoration: BoxDecoration(
                              color: AppTheme.gold,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        if (p.beadCount != null)
                          _spec('عدد الحبات', '${p.beadCount} حبة'),
                        if (p.beadSizeMm != null)
                          _spec('حجم الحبة', '${p.beadSizeMm} مم'),
                        if (p.weightGrams != null)
                          _spec('الوزن', '${p.weightGrams} غ'),
                        if (p.material != null)
                          _spec('الخامة', p.material!),
                        if (p.originCountry != null)
                          _spec('بلد المنشأ', p.originCountry!),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // الوصف
                  if (p.description != null) ...[
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      const Text('التفاصيل',
                        style: TextStyle(fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textDark)),
                      const SizedBox(width: 6),
                      Container(width: 3, height: 20,
                        decoration: BoxDecoration(color: AppTheme.gold,
                          borderRadius: BorderRadius.circular(2))),
                    ]),
                    const SizedBox(height: 8),
                    Text(p.description!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontFamily: 'Tajawal',
                        fontSize: 15, color: AppTheme.textMid, height: 1.6)),
                    const SizedBox(height: 16),
                  ],

                  // ملاحظات
                  const Text('ملاحظات (اختياري)',
                    style: TextStyle(fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textMid)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F6F3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _notes,
                      maxLines: 3,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'أضف ملاحظاتك هنا...',
                        hintStyle: TextStyle(fontFamily: 'Tajawal', color: AppTheme.textLight),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (vm.errorMessage != null) ErrorBanner(vm.errorMessage!),

                  // زر إضافة للسلة
                  _AddToCartButton(product: p),
                  const SizedBox(height: 12),

                  // زر الشراء المباشر
                  Q8Button(
                    label: 'شراء الآن 🛒',
                    isLoading: vm.isLoading,
                    onTap: auth.isGuest
                        ? () => _showGuestAlert(context)
                        : () => _confirmPurchase(context, vm, auth),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _spec(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(value,
        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: AppTheme.textDark)),
      Text(label,
        style: const TextStyle(fontFamily: 'Tajawal',
          fontWeight: FontWeight.w500, fontSize: 14, color: AppTheme.textMid)),
    ]),
  );

  void _showGuestAlert(BuildContext context) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('مستخدم ضيف', textAlign: TextAlign.right,
        style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700)),
      content: const Text('يجب تسجيل الدخول للشراء', textAlign: TextAlign.right,
        style: TextStyle(fontFamily: 'Tajawal')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          onPressed: () {
            Navigator.pop(context);
            context.read<AuthProvider>().appState = AppState.auth;
          },
          child: const Text('تسجيل الدخول')),
      ],
    ),
  );

  void _confirmPurchase(BuildContext ctx, ProductProvider vm, AuthProvider auth) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [AppTheme.goldLight, AppTheme.gold]).createShader(b),
                  child: Text(vm.selectedProduct?.priceFormatted ?? '',
                    style: const TextStyle(fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w800, fontSize: 24, color: Colors.white)),
                ),
                Text(vm.selectedProduct?.name ?? '',
                  style: const TextStyle(fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textDark)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('سيصلك رابط الدفع عبر الواتساب',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: AppTheme.textMid)),
          const SizedBox(height: 20),
          Q8Button(
            label: 'تأكيد الشراء 🛒',
            onTap: () async {
              Navigator.pop(ctx);
              await vm.buyProduct(vm.selectedProduct!.id, notes: _notes.text);
              if (vm.orderSuccess && ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('✅ تم الطلب! سيصلك رابط الدفع عبر الواتساب',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontFamily: 'Tajawal')),
                    backgroundColor: Colors.green));
              }
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: AppTheme.textLight))),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ─── زر إضافة للسلة ──────────────────────────────────────────────────────
class _AddToCartButton extends StatefulWidget {
  final dynamic product;
  const _AddToCartButton({required this.product});
  @override State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton> {
  bool _loading = false;
  bool _added   = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : () => _addToCart(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _added
                ? [Colors.green.shade400, Colors.green.shade600]
                : [AppTheme.goldLight, AppTheme.gold],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (_added ? Colors.green : AppTheme.gold).withOpacity(0.35),
              blurRadius: 12, offset: const Offset(0, 4),
            )
          ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_added ? Icons.check_circle_outline : Icons.shopping_bag_outlined,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _added ? 'تمت الإضافة ✓' : 'أضف للسلة',
                      style: const TextStyle(fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.isGuest) {
      _showGuestDialog(context);
      return;
    }
    setState(() { _loading = true; });
    final ok = await context.read<CartProvider>().addItem(widget.product.id);
    if (!mounted) return;
    setState(() { _loading = false; _added = ok; });
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
              },
              child: const Text('عرض السلة',
                  style: TextStyle(color: Colors.white, fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
            ),
            const Text('✅ أُضيف للسلة',
                textAlign: TextAlign.right,
                style: TextStyle(fontFamily: 'Tajawal', color: Colors.white)),
          ],
        ),
      ));
      // reset back to normal after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _added = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.red,
        content: Text('فشلت الإضافة، حاول مجدداً',
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Tajawal', color: Colors.white)),
      ));
    }
  }

  void _showGuestDialog(BuildContext context) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('مستخدم ضيف', textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700)),
      content: const Text('يجب تسجيل الدخول لإضافة منتجات للسلة',
          textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Tajawal')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          onPressed: () {
            Navigator.pop(context);
            context.read<AuthProvider>().appState = AppState.auth;
          },
          child: const Text('تسجيل الدخول', style: TextStyle(color: Colors.white))),
      ],
    ),
  );
}

