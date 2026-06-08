import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../main.dart';
import '../../widgets/common_widgets.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _orders = await APIService.instance.myOrders();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bg,
    appBar: AppBar(title: const Text('طلباتي 📦')),
    body: _loading
        ? const LoadingBody()
        : _orders.isEmpty
            ? _empty()
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _orders.length,
                  itemBuilder: (_, i) => _OrderCard(order: _orders[i]),
                ),
              ),
  );

  Widget _empty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 80, height: 80,
        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), shape: BoxShape.circle),
        child: const Center(child: Text('📦', style: TextStyle(fontSize: 40)))),
      const SizedBox(height: 16),
      const Text('لا توجد طلبات بعد', style: TextStyle(fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.textDark)),
      const SizedBox(height: 8),
      const Text('ابدأ بتصفح المنتجات وأضف للسلة', style: TextStyle(fontFamily: 'Tajawal',
          fontSize: 14, color: AppTheme.textMid)),
    ]),
  );
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        // ─── Header ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.04),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order.statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${order.statusEmoji} ${order.statusDisplay}',
                  style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                      fontSize: 12, color: order.statusColor)),
              ),
              // Order number
              Text(order.orderNumber,
                style: const TextStyle(fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDark)),
            ],
          ),
        ),

        // ─── Items ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (order.isCartOrder && order.items.isNotEmpty)
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item.totalPrice.toStringAsFixed(3)} د.ك',
                      style: const TextStyle(fontFamily: 'Tajawal',
                          fontSize: 13, color: AppTheme.textMid)),
                    Expanded(child: Text(
                      '${item.productEmoji} ${item.productName} ×${item.quantity}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark))),
                  ],
                ),
              ))
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${order.totalPrice.toStringAsFixed(3)} د.ك',
                    style: const TextStyle(fontFamily: 'Tajawal',
                        fontSize: 13, color: AppTheme.textMid)),
                  Text('${order.productEmoji ?? '📦'} ${order.productName ?? 'منتج'}',
                    style: const TextStyle(fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
                ],
              ),

            const Divider(height: 16),

            // Total + date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDate(order.createdAt),
                  style: const TextStyle(fontFamily: 'Tajawal',
                      fontSize: 12, color: AppTheme.textLight)),
                Row(children: [
                  const Text('المجموع: ', style: TextStyle(fontFamily: 'Tajawal',
                      fontSize: 13, color: AppTheme.textMid)),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                        colors: [AppTheme.goldLight, AppTheme.gold]).createShader(b),
                    child: Text(order.totalFormatted,
                      style: const TextStyle(fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                  ),
                ]),
              ],
            ),

            // Payment link
            if (order.paymentLink != null && order.paymentLink!.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _openLink(context, order.paymentLink!),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.goldLight, AppTheme.gold]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('ادفع الآن 💳', style: TextStyle(fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],

            // Notes
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(child: Text(order.notes!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontFamily: 'Tajawal',
                        fontSize: 12, color: AppTheme.textLight))),
                  const SizedBox(width: 4),
                  const Icon(Icons.notes_outlined, size: 14, color: AppTheme.textLight),
                ],
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return ''; }
  }

  void _openLink(BuildContext context, String url) async {
    // نفتح في المتصفح
    try {
      // ignore: deprecated_member_use
      // نستخدم url_launcher لو موجود وإلا نُظهر الرابط
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('رابط الدفع: $url',
            style: const TextStyle(fontFamily: 'Tajawal')),
        action: SnackBarAction(label: 'نسخ', onPressed: () {}),
      ));
    } catch (_) {}
  }
}
