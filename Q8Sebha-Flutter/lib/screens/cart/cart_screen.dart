import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../main.dart';
import '../../config/app_config.dart';
import '../../widgets/common_widgets.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<CartProvider>().fetchCart());
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('سلة المشتريات 🛒'),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, cart),
              child: const Text('تفريغ', style: TextStyle(color: Colors.red, fontFamily: 'Tajawal')),
            ),
        ],
      ),
      body: cart.isLoading
          ? const LoadingBody()
          : cart.items.isEmpty
              ? _emptyCart()
              : Column(children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16,12,16,8),
                      itemCount: cart.items.length,
                      itemBuilder: (_, i) => _CartItemCard(item: cart.items[i], cart: cart),
                    ),
                  ),
                  _OrderSummary(cart: cart),
                ]),
    );
  }

  Widget _emptyCart() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: const Center(child: Text('🛒', style: TextStyle(fontSize: 44))),
      ),
      const SizedBox(height: 16),
      const Text('سلتك فارغة', style: TextStyle(fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.textDark)),
      const SizedBox(height: 8),
      const Text('أضف منتجات من المتجر', style: TextStyle(fontFamily: 'Tajawal',
          fontSize: 14, color: AppTheme.textMid)),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
        icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
        label: const Text('تصفّح المنتجات',
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, color: Colors.white)),
        onPressed: () => Navigator.pop(context),
      ),
    ]),
  );

  void _confirmClear(BuildContext ctx, CartProvider cart) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      title: const Text('تفريغ السلة', textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, color: Colors.red)),
      content: const Text('هل تريد حذف كل المنتجات؟', textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Tajawal')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () { Navigator.pop(ctx); cart.clearCart(); },
          child: const Text('تفريغ', style: TextStyle(color: Colors.white))),
      ],
    ),
  );
}

// ─── بطاقة عنصر السلة ────────────────────────────────────────────────────
class _CartItemCard extends StatelessWidget {
  final dynamic item;
  final CartProvider cart;
  const _CartItemCard({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    final hasImg = item.imageUrls.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0,3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          // أزرار الكمية
          Column(children: [
            _QtyBtn(icon: Icons.add, onTap: () => cart.updateQuantity(item.id, item.quantity + 1)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('${item.quantity}',
                style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 16))),
            _QtyBtn(
              icon: item.quantity == 1 ? Icons.delete_outline : Icons.remove,
              onTap: () => item.quantity == 1
                  ? cart.removeItem(item.id)
                  : cart.updateQuantity(item.id, item.quantity - 1),
              color: item.quantity == 1 ? Colors.red : null,
            ),
          ]),
          const SizedBox(width: 12),
          // صورة
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hasImg
                ? Image.network(AppConfig.imageUrl(item.imageUrls[0]),
                    width: 70, height: 70, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _emojiBox(item.emoji))
                : _emojiBox(item.emoji),
          ),
          const SizedBox(width: 12),
          // اسم وسعر
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(item.name, textAlign: TextAlign.right, maxLines: 2,
                style: const TextStyle(fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark)),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('د.ك', style: TextStyle(fontFamily: 'Tajawal',
                    fontSize: 11, color: AppTheme.textLight)),
                const SizedBox(width: 4),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                      colors: [AppTheme.goldLight, AppTheme.gold]).createShader(b),
                  child: Text(item.totalFormatted,
                    style: const TextStyle(fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
                ),
              ]),
              if (item.quantity > 1)
                Text('${item.priceFormatted} د.ك × ${item.quantity}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontFamily: 'Tajawal',
                      fontSize: 12, color: AppTheme.textLight)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _emojiBox(String emoji) => Container(
    width: 70, height: 70, color: const Color(0xFFF0EDE8),
    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 32))));
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _QtyBtn({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color ?? AppTheme.primary),
    ),
  );
}

// ─── ملخص الطلب ──────────────────────────────────────────────────────────
class _OrderSummary extends StatelessWidget {
  final CartProvider cart;
  const _OrderSummary({required this.cart});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0,-4))],
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: Column(children: [
      // handle
      Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2))),
      // المجموع
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
                colors: [AppTheme.goldLight, AppTheme.gold]).createShader(b),
            child: Text(cart.totalFormatted,
              style: const TextStyle(fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w800, fontSize: 26, color: Colors.white)),
          ),
          const SizedBox(width: 6),
          const Text('د.ك', style: TextStyle(fontFamily: 'Tajawal',
              fontSize: 14, color: AppTheme.textLight)),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('المجموع', style: TextStyle(fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textDark)),
          Text('${cart.count} منتج', style: const TextStyle(fontFamily: 'Tajawal',
              fontSize: 12, color: AppTheme.textMid)),
        ]),
      ]),
      const SizedBox(height: 16),
      // زر إتمام الطلب
      Q8Button(
        label: 'إتمام الطلب 🛒',
        onTap: () => _confirmOrder(context),
      ),
    ]),
  );

  void _confirmOrder(BuildContext context) => showModalBottomSheet(
    context: context,
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
        const Text('تأكيد الطلب', style: TextStyle(fontFamily: 'Tajawal',
            fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.textDark)),
        const SizedBox(height: 12),
        Text('المجموع: ${cart.totalFormatted} د.ك (${cart.count} منتج)',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16, color: AppTheme.textMid)),
        const SizedBox(height: 8),
        const Text('سيصلك رابط الدفع عبر الواتساب',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: AppTheme.textLight)),
        const SizedBox(height: 20),
        Q8Button(
          label: 'تأكيد',
          onTap: () async {
            Navigator.pop(context);
            // TODO: إرسال الطلب للبيكند
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ تم إرسال طلبك! سيصلك رابط الدفع',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontFamily: 'Tajawal')),
                backgroundColor: Colors.green));
          },
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء', style: TextStyle(color: AppTheme.textLight))),
        const SizedBox(height: 8),
      ]),
    ),
  );
}
