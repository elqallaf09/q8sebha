import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../main.dart';
import '../../config/app_config.dart';
import '../../widgets/common_widgets.dart';

class AuctionDetailScreen extends StatefulWidget {
  final int auctionId;
  const AuctionDetailScreen({super.key, required this.auctionId});
  @override State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  Timer? _ticker;
  final _payLink = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<AuctionProvider>().fetchAuction(widget.auctionId));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _ticker?.cancel(); _payLink.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final vm   = context.watch<AuctionProvider>();
    final auth = context.watch<AuthProvider>();
    final a    = vm.selectedAuction;

    if (vm.isLoading && a == null) return const Scaffold(body: LoadingBody());
    if (a == null) return const Scaffold(
      body: Center(child: Text('خطأ في التحميل',
        style: TextStyle(fontFamily: 'Tajawal'))));

    final secs = a.timeRemaining.inSeconds;
    final isUrgent  = secs < 60;
    final isWarning = secs >= 60 && secs < 300;
    final timerColor = isUrgent ? Colors.red : isWarning ? Colors.orange : const Color(0xFF4CAF50);

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
          // ─── صورة المزاد ─────────────────────────────────────────────
          SizedBox(
            height: 280,
            child: Stack(children: [
              a.imageUrls.isEmpty
                  ? Container(
                      color: const Color(0xFFF0EDE8),
                      child: const Center(child: Text('📿', style: TextStyle(fontSize: 100))))
                  : Image.network(
                      AppConfig.imageUrl(a.primaryImage),
                      width: double.infinity, height: 280, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text('📿', style: TextStyle(fontSize: 100)))),
              // تدرج
              Positioned(bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    ),
                  ),
                )),
              // السعر الحالي
              Positioned(bottom: 16, right: 16,
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('السعر الحالي',
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white70)),
                  Text(a.currentPriceFormatted,
                    style: const TextStyle(fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w800, fontSize: 26, color: Colors.white)),
                ])),
              // عداد الوقت
              Positioned(bottom: 20, left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isUrgent ? Colors.red.withOpacity(0.9) : Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(children: [
                    Icon(Icons.timer, color: timerColor, size: 15),
                    const SizedBox(width: 5),
                    Text(a.countdownString,
                      style: const TextStyle(fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                  ]),
                )),
              // badge نشط/انتهى
              Positioned(top: 60, left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (a.isActive ? Colors.green : Colors.red).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(a.isActive ? '🟢 نشط' : '🔴 انتهى',
                    style: const TextStyle(fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white)),
                )),
            ]),
          ),

          // ─── بطاقة المعلومات ─────────────────────────────────────────
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
                  // عنوان
                  Text(a.title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.textDark)),
                  const SizedBox(height: 16),

                  // شريط الأسعار
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${a.bidsCount} مزايدة',
                          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: AppTheme.textMid)),
                        Text('الحد الأعلى: ${a.maxPriceFormatted}',
                          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: AppTheme.textLight)),
                      ]),
                      Text('الابتدائي: ${a.startingPrice.toStringAsFixed(3)} د.ك',
                        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: AppTheme.textLight)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  PriceRangeBar(fraction: a.progressFraction),
                  const SizedBox(height: 16),

                  // بائع / شروط
                  if (a.sellerName != null) _infoBox('👤 البائع', a.sellerName!),
                  if (a.sellerTerms != null && a.sellerTerms!.isNotEmpty)
                    _infoBox('📋 شروط البائع', a.sellerTerms!),

                  if (vm.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    ErrorBanner(vm.errorMessage!),
                  ],
                  const SizedBox(height: 16),

                  // ─── زر المزايدة ────────────────────────────────────
                  if (a.isActive)
                    auth.isGuest
                        ? Q8Button(
                            label: 'سجّل الدخول للمزايدة',
                            color: AppTheme.textMid,
                            onTap: () => context.read<AuthProvider>().appState = AppState.auth)
                        : Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primary, Color(0xFF2D2D55)]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(
                                color: AppTheme.primary.withOpacity(0.3),
                                blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: vm.isLoading ? null : () => _confirmBid(context, vm, a),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  alignment: Alignment.center,
                                  child: vm.isLoading
                                      ? const SizedBox(width: 24, height: 24,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                          const Text('🔨', style: TextStyle(fontSize: 18)),
                                          const SizedBox(width: 8),
                                          Text(
                                            'زايد الآن +${a.bidIncrement.toStringAsFixed(3)} د.ك',
                                            style: const TextStyle(fontFamily: 'Tajawal',
                                              fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                                        ]),
                                ),
                              ),
                            ),
                          ),

                  // ─── البائع: رابط دفع ───────────────────────────────
                  if (!a.isActive && a.sellerId == auth.currentUser?.id && a.winnerId != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          const SizedBox(width: 6),
                          Text('الفائز: ${a.winnerName ?? "#${a.winnerId}"}',
                            style: const TextStyle(fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w700, fontSize: 15)),
                          const Icon(Icons.emoji_events, color: AppTheme.gold, size: 20),
                        ]),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            controller: _payLink,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'رابط الدفع (واتساب/كاشير...)',
                              hintStyle: TextStyle(fontFamily: 'Tajawal', color: AppTheme.textLight),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Q8Button(
                          label: 'إرسال رابط الدفع للفائز',
                          color: Colors.green,
                          onTap: () async {
                            final ok = await vm.sendPaymentLink(a.id, _payLink.text);
                            if (ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ تم إرسال الرابط',
                                  style: TextStyle(fontFamily: 'Tajawal'))));
                          },
                        ),
                        const SizedBox(height: 8),
                        Q8Button(
                          label: 'إبلاغ عن عدم الدفع ⚠️',
                          color: Colors.red,
                          onTap: () => _confirmReport(context, vm, a.id),
                        ),
                      ]),
                    ),
                  ],

                  // ─── آخر المزايدات ──────────────────────────────────
                  if (vm.bids.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      const Text('آخر المزايدات',
                        style: TextStyle(fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textDark)),
                      const SizedBox(width: 6),
                      Container(width: 3, height: 20,
                        decoration: BoxDecoration(color: AppTheme.gold,
                          borderRadius: BorderRadius.circular(2))),
                    ]),
                    const SizedBox(height: 10),
                    ...List.generate(vm.bids.take(10).length, (i) {
                      final bid = vm.bids[i];
                      final isTop = i == 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isTop ? AppTheme.primary.withOpacity(0.05) : const Color(0xFFF7F6F3),
                          borderRadius: BorderRadius.circular(12),
                          border: isTop ? Border.all(color: AppTheme.gold.withOpacity(0.3)) : null,
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Row(children: [
                            if (isTop) const Text('🥇 ', style: TextStyle(fontSize: 14)),
                            Text(bid.amountFormatted,
                              style: TextStyle(fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w700, fontSize: 14,
                                color: isTop ? AppTheme.primary : AppTheme.textDark)),
                          ]),
                          Row(children: [
                            Text(bid.bidderName ?? 'مجهول',
                              style: const TextStyle(fontFamily: 'Tajawal',
                                fontSize: 14, color: AppTheme.textMid)),
                            const SizedBox(width: 6),
                            const Icon(Icons.person_outline, size: 16, color: AppTheme.textLight),
                          ]),
                        ]),
                      );
                    }),
                  ],
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _infoBox(String title, String content) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F6F3),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(title, style: const TextStyle(fontFamily: 'Tajawal',
        fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark)),
      const SizedBox(height: 4),
      Text(content, textAlign: TextAlign.right,
        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: AppTheme.textMid)),
    ]),
  );

  void _confirmBid(BuildContext ctx, AuctionProvider vm, auction) {
    final nextAmount = (auction.currentPrice + auction.bidIncrement).toStringAsFixed(3);
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
          const Text('🔨', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('تأكيد المزايدة',
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.goldLight, AppTheme.gold]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$nextAmount د.ك',
              style: const TextStyle(fontFamily: 'Tajawal',
                fontWeight: FontWeight.w800, fontSize: 24, color: Colors.white)),
          ),
          const SizedBox(height: 20),
          Q8Button(
            label: 'تأكيد المزايدة',
            onTap: () async {
              Navigator.pop(ctx);
              await vm.placeBid(auction.id, auction.currentPrice + auction.bidIncrement);
              if (vm.bidSuccess && ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('✅ تم تسجيل مزايدتك!',
                    style: TextStyle(fontFamily: 'Tajawal')),
                  backgroundColor: Colors.green));
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

  void _confirmReport(BuildContext ctx, AuctionProvider vm, int auctionId) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('إبلاغ عن عدم الدفع', textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Tajawal', color: Colors.red, fontWeight: FontWeight.w700)),
        content: const Text('سيتم حظر المشتري من التطبيق. هل أنت متأكد؟',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Tajawal')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await vm.reportNonPayment(auctionId);
              if (ok && ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('تم الإبلاغ وحظر المشتري',
                    style: TextStyle(fontFamily: 'Tajawal')),
                  backgroundColor: Colors.red));
            },
            child: const Text('إبلاغ وحظر')),
        ],
      ),
    );
  }
}
