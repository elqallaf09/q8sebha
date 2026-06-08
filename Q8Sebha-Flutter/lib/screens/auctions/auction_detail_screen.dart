import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../providers/auction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../main.dart';
import '../../config/app_config.dart';
import '../../widgets/common_widgets.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class AuctionDetailScreen extends StatefulWidget {
  final int auctionId;
  const AuctionDetailScreen({super.key, required this.auctionId});
  @override State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  Timer? _ticker;
  final _payLink   = TextEditingController();
  final _bidAmtCtrl = TextEditingController();
  bool _isFav      = false;
  bool _favLoading = false;
  bool _showAllBids = false;
  Map<String,dynamic>? _autoBid;
  List<Map<String,dynamic>> _allBids = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuctionProvider>().fetchAuction(widget.auctionId);
      _loadExtras();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
  }

  Future<void> _loadExtras() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      try {
        final fav = await APIService.instance.checkFavoriteAuction(widget.auctionId);
        final ab  = await APIService.instance.getAutoBid(widget.auctionId);
        if (mounted) setState(() { _isFav = fav; _autoBid = ab; });
      } catch (_) {}
    }
    try {
      final bids = await APIService.instance.auctionBids(widget.auctionId);
      if (mounted) setState(() => _allBids = bids);
    } catch (_) {}
  }

  Future<void> _toggleFav() async {
    if (!context.read<AuthProvider>().isLoggedIn) return;
    setState(() => _favLoading = true);
    try {
      final action = await APIService.instance.toggleFavoriteAuction(widget.auctionId);
      setState(() => _isFav = action == 'added');
    } catch (_) {}
    setState(() => _favLoading = false);
  }

  void _openWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _shareAuction(Auction a) {
    Share.share(
      '🔨 مزاد: ${a.title}\n'
      '💰 السعر الحالي: ${a.currentPriceFormatted}\n'
      '⏰ ينتهي: ${a.countdownString}\n\n'
      'تابع المزاد على Q8Sebha 📿',
    );
  }

  void _openImageGallery(BuildContext ctx, List<String> urls, int initial) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => _ImageGallery(urls: urls, initial: initial)));
  }

  @override
  void dispose() { _ticker?.cancel(); _payLink.dispose(); _bidAmtCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final vm   = context.watch<AuctionProvider>();
    final auth = context.watch<AuthProvider>();
    final a    = vm.selectedAuction;

    if (vm.isLoading && a == null) return const Scaffold(body: LoadingBody());
    if (a == null) return const Scaffold(
      body: Center(child: Text('خطأ في التحميل', style: TextStyle(fontFamily: 'Tajawal'))));

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
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
        ),
        actions: [
          // زر المفضلة
          GestureDetector(
            onTap: _toggleFav,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
              padding: const EdgeInsets.all(8),
              child: _favLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(_isFav ? Icons.favorite : Icons.favorite_border,
                      color: _isFav ? Colors.red : Colors.white, size: 20),
            ),
          ),
          // زر المشاركة
          GestureDetector(
            onTap: () => _shareAuction(a),
            child: Container(
              margin: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 4),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.share, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // ─── صور المزاد (قابلة للنقر والزووم) ───────────────────────────
          SizedBox(
            height: 280,
            child: Stack(children: [
              a.imageUrls.isEmpty
                  ? Container(color: const Color(0xFFF0EDE8),
                      child: const Center(child: Text('📿', style: TextStyle(fontSize: 100))))
                  : a.imageUrls.length == 1
                      ? GestureDetector(
                          onTap: () => _openImageGallery(context,
                              a.imageUrls.map((u) => AppConfig.imageUrl(u)).toList(), 0),
                          child: CachedNetworkImage(imageUrl:AppConfig.imageUrl(a.primaryImage),
                              width: double.infinity, height: 280, fit: BoxFit.cover,
                              errorBuilder: (_,__,___) => const Center(child: Text('📿', style: TextStyle(fontSize: 100)))))
                      : PageView.builder(
                          itemCount: a.imageUrls.length,
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => _openImageGallery(context,
                                a.imageUrls.map((u) => AppConfig.imageUrl(u)).toList(), i),
                            child: CachedNetworkImage(imageUrl:AppConfig.imageUrl(a.imageUrls[i]),
                                width: double.infinity, height: 280, fit: BoxFit.cover,
                                errorBuilder: (_,__,___) => const Center(child: Text('📿', style: TextStyle(fontSize: 80)))),
                          ),
                        ),
              // تدرج
              Positioned(bottom: 0, left: 0, right: 0,
                child: Container(height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent])))),
              // السعر الحالي
              Positioned(bottom: 16, right: 16,
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('السعر الحالي', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white70)),
                  Text(a.currentPriceFormatted,
                    style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800, fontSize: 26, color: Colors.white)),
                ])),
              // عداد الوقت
              Positioned(bottom: 20, left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isUrgent ? Colors.red.withOpacity(0.9) : Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24)),
                  child: Row(children: [
                    Icon(Icons.timer, color: timerColor, size: 15),
                    const SizedBox(width: 5),
                    Text(a.countdownString,
                      style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                  ]),
                )),
              // badge الحالة
              Positioned(top: 60, left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: a.isActive ? Colors.green.withOpacity(0.85)
                        : a.isReserveNotMet ? Colors.orange.withOpacity(0.9) : Colors.red.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(a.statusLabel,
                    style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white)),
                )),
              // مؤشر صور متعددة
              if (a.imageUrls.length > 1)
                Positioned(top: 60, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.photo_library, color: Colors.white, size: 13),
                      const SizedBox(width: 3),
                      Text('${a.imageUrls.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Tajawal')),
                    ]),
                  )),
            ]),
          ),

          // ─── بطاقة المعلومات ─────────────────────────────────────────────
          Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  // عنوان
                  Text(a.title, textAlign: TextAlign.right,
                    style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800,
                        fontSize: 20, color: AppTheme.textDark)),
                  const SizedBox(height: 16),

                  // شريط الأسعار
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${a.bidsCount} مزايدة',
                        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: AppTheme.textMid)),
                      Text('الحد الأعلى: ${a.maxPriceFormatted}',
                        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: AppTheme.textLight)),
                    ]),
                    Text('الابتدائي: ${a.startingPrice.toStringAsFixed(3)} د.ك',
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: AppTheme.textLight)),
                  ]),
                  const SizedBox(height: 8),
                  PriceRangeBar(fraction: a.progressFraction),
                  const SizedBox(height: 16),

                  // ─── بائع + واتساب ──────────────────────────────────────
                  if (a.sellerName != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F6F3),
                        borderRadius: BorderRadius.circular(14)),
                      child: Row(children: [
                        // زر واتساب
                        if (a.sellerPhone != null)
                          GestureDetector(
                            onTap: () => _openWhatsApp(a.sellerPhone!),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366),
                                borderRadius: BorderRadius.circular(10)),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Text('💬', style: TextStyle(fontSize: 14)),
                                SizedBox(width: 4),
                                Text('واتساب', style: TextStyle(
                                    fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                                    fontSize: 12, color: Colors.white)),
                              ]),
                            ),
                          ),
                        const Spacer(),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('👤 البائع', style: const TextStyle(fontFamily: 'Tajawal',
                              fontSize: 11, color: AppTheme.textLight)),
                          Text(a.sellerName!,
                            style: const TextStyle(fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark)),
                        ]),
                      ]),
                    ),

                  if (a.sellerTerms != null && a.sellerTerms!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _infoBox('📋 شروط البائع', a.sellerTerms!),
                  ],

                  if (vm.errorMessage != null) ...[
                    const SizedBox(height: 8), ErrorBanner(vm.errorMessage!),
                  ],

                  // ─── reserve price ───────────────────────────────────────
                  if (a.reservePrice != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E8), borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.gold.withOpacity(0.4))),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('${a.reservePrice!.toStringAsFixed(3)} د.ك',
                          style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                              fontSize: 14, color: AppTheme.gold)),
                        const Row(children: [
                          Text('الحد الأدنى المقبول', style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: AppTheme.textMid)),
                          SizedBox(width: 6),
                          Icon(Icons.shield_outlined, color: AppTheme.gold, size: 16),
                        ]),
                      ]),
                    ),
                  ],

                  // ─── عالمرجوع ────────────────────────────────────────────
                  if (a.isReserveNotMet) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.orange.shade50, Colors.amber.shade50]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.shade200)),
                      child: Column(children: [
                        const Text('↩️', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 8),
                        const Text('عالمرجوع',
                          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800,
                              fontSize: 22, color: Colors.orange)),
                        const SizedBox(height: 4),
                        Text('المزاد انتهى لكن السعر لم يصل للحد المقبول (${a.reservePrice?.toStringAsFixed(3)} د.ك)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: AppTheme.textMid)),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ─── أزرار المزايدة ──────────────────────────────────────
                  if (a.isActive) ...[
                    auth.isGuest
                        ? Q8Button(label: 'سجّل الدخول للمزايدة', color: AppTheme.textMid,
                            onTap: () => context.read<AuthProvider>().appState = AppState.auth)
                        : Column(children: [
                            // زر المزايدة العادية
                            _BidButton(
                              label: 'زايد الآن +${a.bidIncrement.toStringAsFixed(3)} د.ك',
                              isLoading: vm.isLoading,
                              onTap: () => _confirmBid(context, vm, a),
                            ),
                            const SizedBox(height: 10),
                            // زر المزايدة التلقائية
                            _autoBid != null
                                ? _AutoBidActive(
                                    maxAmount: (_autoBid!['max_amount'] as num).toDouble(),
                                    onCancel: () async {
                                      await APIService.instance.cancelAutoBid(widget.auctionId);
                                      setState(() => _autoBid = null);
                                    },
                                  )
                                : OutlinedButton.icon(
                                    onPressed: () => _showAutoBidSheet(context, a),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 48),
                                      side: const BorderSide(color: AppTheme.primary),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    icon: const Icon(Icons.auto_mode, color: AppTheme.primary),
                                    label: const Text('مزايدة تلقائية',
                                      style: TextStyle(fontFamily: 'Tajawal', color: AppTheme.primary,
                                          fontWeight: FontWeight.w700)),
                                  ),
                          ]),
                  ],

                  // ─── البائع: رابط دفع ────────────────────────────────────
                  if (!a.isActive && a.sellerId == auth.currentUser?.id && a.winnerId != null) ...[
                    const SizedBox(height: 16),
                    _SellerPanel(
                      auction: a, payLinkCtrl: _payLink, vm: vm,
                      onReport: () => _confirmReport(context, vm, a.id),
                    ),
                  ],

                  // ─── تقييم البائع (الفائز فقط بعد انتهاء المزاد) ────────
                  if (!a.isActive && a.status == 'ended' &&
                      auth.currentUser?.id == a.winnerId &&
                      a.sellerId != auth.currentUser?.id) ...[
                    const SizedBox(height: 16),
                    _RatingSection(sellerId: a.sellerId, auctionId: a.id),
                  ],

                  // ─── سجل المزايدات ──────────────────────────────────────
                  const SizedBox(height: 20),
                  _BidsSection(
                    bids: _allBids.isEmpty ? vm.bids.map((b) => {
                      'amount': b.amount, 'bidder_name': b.bidderName ?? 'مجهول',
                    }).toList() : _allBids,
                    showAll: _showAllBids,
                    onToggle: () => setState(() => _showAllBids = !_showAllBids),
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

  Widget _infoBox(String title, String content) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFF7F6F3), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(title, style: const TextStyle(fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark)),
      const SizedBox(height: 4),
      Text(content, textAlign: TextAlign.right,
        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: AppTheme.textMid)),
    ]),
  );

  void _confirmBid(BuildContext ctx, AuctionProvider vm, Auction a) {
    final nextAmount = (a.currentPrice + a.bidIncrement).toStringAsFixed(3);
    showModalBottomSheet(
      context: ctx, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
              borderRadius: BorderRadius.circular(12)),
            child: Text('$nextAmount د.ك',
              style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800,
                  fontSize: 24, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          const Text('سيتم تسجيل مزايدتك فوراً',
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('إلغاء',
                  style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  vm.placeBid(widget.auctionId, a.currentPrice + a.bidIncrement);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('تأكيد المزايدة',
                  style: TextStyle(fontFamily: 'Tajawal', color: Colors.white,
                      fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _confirmReport(BuildContext ctx, AuctionProvider vm, int auctionId) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('الإبلاغ عن عدم الدفع', textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700)),
        content: const Text('هل تريد الإبلاغ عن المشتري لعدم الدفع؟\nسيتم مراجعة الحالة من قبل الإدارة.',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Tajawal')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.reportNonPayment(auctionId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إبلاغ', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAutoBidSheet(BuildContext ctx, Auction a) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('🤖', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            const Text('مزايدة تلقائية',
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 4),
            const Text('سيزايد النظام تلقائياً نيابةً عنك حتى تصل لسقف المبلغ',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'الحد الأقصى (د.ك)',
                hintStyle: const TextStyle(fontFamily: 'Tajawal'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final max = double.tryParse(ctrl.text);
                if (max == null || max <= a.currentPrice) return;
                Navigator.pop(ctx);
                try {
                  final ab = await APIService.instance.setAutoBid(widget.auctionId, max);
                  setState(() => _autoBid = ab['data']);
                } catch (_) {}
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('تفعيل المزايدة التلقائية',
                style: TextStyle(fontFamily: 'Tajawal', color: Colors.white,
                    fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}

// ─── زر المزايدة ─────────────────────────────────────────────────────────────
class _BidButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  const _BidButton({required this.label, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF2D2D55)],
          begin: Alignment.centerRight, end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF1A1A2E).withOpacity(0.3),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: isLoading
          ? const Center(child: SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
          : Text(label, textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800,
                  fontSize: 16, color: Colors.white)),
    ),
  );
}

// ─── مزايدة تلقائية نشطة ─────────────────────────────────────────────────────
class _AutoBidActive extends StatelessWidget {
  final double maxAmount;
  final VoidCallback onCancel;
  const _AutoBidActive({required this.maxAmount, required this.onCancel});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.green.shade300),
    ),
    child: Row(children: [
      const Text('🤖', style: TextStyle(fontSize: 20)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('مزايدة تلقائية نشطة',
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                fontSize: 13, color: Colors.green)),
          Text('الحد: ${maxAmount.toStringAsFixed(3)} د.ك',
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.green)),
        ]),
      ),
      TextButton(
        onPressed: onCancel,
        style: TextButton.styleFrom(foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 8)),
        child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
      ),
    ]),
  );
}

// ─── لوحة البائع (إرسال رابط دفع / إبلاغ) ───────────────────────────────────
class _SellerPanel extends StatelessWidget {
  final Auction auction;
  final TextEditingController payLinkCtrl;
  final dynamic vm;
  final VoidCallback onReport;
  const _SellerPanel({required this.auction, required this.payLinkCtrl,
      required this.vm, required this.onReport});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F6F3),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE0DED8)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      const Text('🏪 لوحة البائع',
        style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
            fontSize: 15, color: AppTheme.textDark)),
      const SizedBox(height: 12),
      TextField(
        controller: payLinkCtrl,
        decoration: InputDecoration(
          hintText: 'رابط الدفع (اختياري)',
          hintStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReport,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.report, color: Colors.red, size: 16),
            label: const Text('إبلاغ', style: TextStyle(fontFamily: 'Tajawal', color: Colors.red, fontSize: 13)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: payLinkCtrl.text.isNotEmpty
                ? () => vm.sendPaymentLink(auction.id, payLinkCtrl.text.trim())
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.send, color: Colors.white, size: 16),
            label: const Text('إرسال رابط الدفع',
              style: TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontSize: 13)),
          ),
        ),
      ]),
    ]),
  );
}

// ─── قسم التقييم (حقيقي من API فقط) ─────────────────────────────────────────
class _RatingSection extends StatefulWidget {
  final int sellerId, auctionId;
  const _RatingSection({required this.sellerId, required this.auctionId});
  @override State<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<_RatingSection> {
  double _selectedRating = 0;
  final _comment = TextEditingController();
  bool _submitted = false;
  bool _loading = false;
  String? _error;
  // تقييمات البائع الحقيقية
  List<dynamic> _reviews = [];
  double? _avgRating;
  int _reviewCount = 0;
  bool _reviewsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() { _comment.dispose(); super.dispose(); }

  Future<void> _loadReviews() async {
    try {
      final r = await APIService.instance.sellerReviews(widget.sellerId);
      final data = r['data'];
      setState(() {
        _reviews     = (data['reviews'] as List?) ?? [];
        _avgRating   = (data['average'] as num?)?.toDouble();
        _reviewCount = (data['count'] as num?)?.toInt() ?? 0;
        _reviewsLoading = false;
      });
    } catch (_) {
      setState(() => _reviewsLoading = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      setState(() => _error = 'اختر تقييماً من 1 إلى 5 نجوم');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await APIService.instance.addReview(
        widget.sellerId, _selectedRating,
        comment: _comment.text.trim().isNotEmpty ? _comment.text.trim() : null,
        auctionId: widget.auctionId,
      );
      setState(() { _submitted = true; _loading = false; });
    } on APIError catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'خطأ في الإرسال'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        // ─── عنوان + متوسط التقييم الحقيقي ───────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          if (!_reviewsLoading && _avgRating != null)
            Row(children: [
              const Icon(Icons.star_rounded, color: AppTheme.gold, size: 18),
              const SizedBox(width: 4),
              Text('${_avgRating!.toStringAsFixed(1)} (${_reviewCount})',
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13,
                    fontWeight: FontWeight.w700, color: AppTheme.gold)),
            ])
          else if (_reviewsLoading)
            const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.gold)),
          const Text('⭐ قيّم البائع',
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                fontSize: 15, color: AppTheme.textDark)),
        ]),
        const SizedBox(height: 12),

        if (_submitted) ...[
          // ─── تم الإرسال ─────────────────────────────────────────────
          const Center(child: Column(children: [
            Text('✅', style: TextStyle(fontSize: 36)),
            SizedBox(height: 8),
            Text('شكراً! تم إرسال تقييمك',
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                  fontSize: 15, color: Colors.green)),
          ])),
        ] else ...[
          // ─── نجوم التقييم ────────────────────────────────────────────
          Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = star.toDouble()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    star <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppTheme.gold, size: 36,
                  ),
                ),
              );
            })),
          ),
          const SizedBox(height: 12),

          // ─── تعليق ───────────────────────────────────────────────────
          TextField(
            controller: _comment,
            maxLines: 2,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'اكتب تعليقاً (اختياري)...',
              hintStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(fontFamily: 'Tajawal',
                fontSize: 12, color: Colors.red), textAlign: TextAlign.right),
          ],
          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gold,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('إرسال التقييم',
                    style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                        color: Colors.white)),
          ),
        ],

        // ─── تقييمات البائع السابقة (حقيقية) ──────────────────────────
        if (!_reviewsLoading && _reviews.isNotEmpty) ...[
          const Divider(height: 24),
          const Align(alignment: Alignment.centerRight,
            child: Text('تقييمات البائع',
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                  fontSize: 13, color: AppTheme.textMid))),
          const SizedBox(height: 8),
          ...(_reviews.take(3).map((r) => _ReviewItem(review: r))),
        ],
      ]),
    );
  }
}

// ─── عنصر تقييم واحد ─────────────────────────────────────────────────────────
class _ReviewItem extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating  = (review['rating'] as num?)?.toDouble() ?? 0;
    final name    = review['reviewer_name'] as String? ?? 'مجهول';
    final comment = review['comment'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEFEDE8)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: List.generate(5, (i) => Icon(
            (i + 1) <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: AppTheme.gold, size: 14,
          ))),
          Text(name, style: const TextStyle(fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textDark)),
        ]),
        if (comment != null && comment.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(comment, textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: AppTheme.textMid)),
        ],
      ]),
    );
  }
}

// ─── سجل المزايدات ───────────────────────────────────────────────────────────
class _BidsSection extends StatelessWidget {
  final List<Map<String, dynamic>> bids;
  final bool showAll;
  final VoidCallback onToggle;
  const _BidsSection({required this.bids, required this.showAll, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    if (bids.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F6F3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text('لا توجد مزايدات بعد',
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: AppTheme.textLight)),
        ),
      );
    }

    final shown = showAll ? bids : bids.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${bids.length} مزايدة',
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: AppTheme.textLight)),
          const Text('🔨 سجل المزايدات',
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                fontSize: 14, color: AppTheme.textDark)),
        ]),
        const SizedBox(height: 10),
        ...shown.asMap().entries.map((e) {
          final i = e.key;
          final b = e.value;
          final amount = (b['amount'] as num).toStringAsFixed(3);
          final name   = b['bidder_name'] as String? ?? 'مجهول';
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: i == 0 ? AppTheme.gold.withOpacity(0.12) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: i == 0 ? AppTheme.gold.withOpacity(0.4) : Colors.transparent),
            ),
            child: Row(children: [
              Text('$amount د.ك',
                style: TextStyle(
                  fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 13,
                  color: i == 0 ? AppTheme.gold : AppTheme.textDark)),
              const Spacer(),
              if (i == 0) const Icon(Icons.emoji_events, color: AppTheme.gold, size: 14),
              const SizedBox(width: 4),
              Text(name,
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: AppTheme.textMid)),
            ]),
          );
        }),
        if (bids.length > 5) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onToggle,
            child: Center(
              child: Text(
                showAll ? 'عرض أقل ▲' : 'عرض الكل (${bids.length}) ▼',
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12,
                    color: AppTheme.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

// ─── معرض الصور مع زووم ──────────────────────────────────────────────────────
class _ImageGallery extends StatefulWidget {
  final List<String> urls;
  final int initial;
  const _ImageGallery({required this.urls, required this.initial});
  @override State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  late int _current;

  @override
  void initState() { super.initState(); _current = widget.initial; }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${_current + 1} / ${widget.urls.length}',
          style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white)),
        centerTitle: true,
      ),
      body: PhotoViewGallery.builder(
        itemCount: widget.urls.length,
        pageController: PageController(initialPage: widget.initial),
        onPageChanged: (i) => setState(() => _current = i),
        builder: (_, i) => PhotoViewGalleryPageOptions(
          imageProvider: NetworkImage(widget.urls[i]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          errorBuilder: (_, __, ___) => const Center(
            child: Text('📿', style: TextStyle(fontSize: 100))),
        ),
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}
