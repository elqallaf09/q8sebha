import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../main.dart';
import '../../config/app_config.dart';
import '../../widgets/common_widgets.dart';
import 'auction_detail_screen.dart';
import 'create_auction_screen.dart';

class AuctionListScreen extends StatefulWidget {
  const AuctionListScreen({super.key});
  @override State<AuctionListScreen> createState() => _AuctionListScreenState();
}

class _AuctionListScreenState extends State<AuctionListScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<AuctionProvider>().fetchAuctions());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() { _ticker?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final vm   = context.watch<AuctionProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          // ─── AppBar ──────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            title: const Text('المزادات الحية 🔨',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                    fontSize: 18, color: Colors.white)),
            centerTitle: true,
            actions: [
              if (!auth.isGuest)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CreateAuctionScreen()));
                      if (context.mounted) context.read<AuctionProvider>().fetchAuctions();
                    },
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text('إضافة',
                        style: TextStyle(fontFamily: 'Tajawal', color: Colors.white,
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(36),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        const Icon(Icons.circle, color: Color(0xFF4CAF50), size: 8),
                        const SizedBox(width: 6),
                        Text('${vm.auctions.length} مزاد نشط',
                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12,
                                color: Colors.white70)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── المحتوى ─────────────────────────────────────────────────
          if (vm.isLoading)
            const SliverFillRemaining(child: LoadingBody())
          else if (vm.auctions.isEmpty)
            const SliverFillRemaining(
                child: EmptyState(emoji: '🔨', message: 'لا توجد مزادات نشطة'))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _AuctionCard(
                    auction: vm.auctions[i],
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AuctionDetailScreen(auctionId: vm.auctions[i].id))),
                  ),
                  childCount: vm.auctions.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── بطاقة المزاد ─────────────────────────────────────────────────────────
class _AuctionCard extends StatelessWidget {
  final Auction auction;
  final VoidCallback onTap;
  const _AuctionCard({required this.auction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final secs = auction.timeRemaining.inSeconds;
    final isUrgent  = secs < 60;
    final isWarning = secs >= 60 && secs < 300;
    final timerColor = isUrgent ? Colors.red
        : isWarning ? Colors.orange
        : AppTheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06),
                blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: isUrgent
              ? Border.all(color: Colors.red.shade200, width: 1.5)
              : null,
        ),
        child: Column(
          children: [
            // ─── الصورة مع overlay ──────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 160,
                    child: auction.imageUrls.isEmpty
                        ? Container(
                            color: const Color(0xFFF0EDE8),
                            child: const Center(
                              child: Text('📿', style: TextStyle(fontSize: 60))))
                        : Image.network(
                            AppConfig.imageUrl(auction.primaryImage),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFF0EDE8),
                              child: const Center(
                                child: Text('📿', style: TextStyle(fontSize: 60)))),
                          ),
                  ),
                  // تدرج سفلي
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // السعر الحالي
                  Positioned(
                    bottom: 10, right: 12,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('السعر الحالي',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 11,
                              color: Colors.white70)),
                      Text(auction.currentPriceFormatted,
                          style: const TextStyle(fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
                    ]),
                  ),
                  // عداد الوقت
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? Colors.red.withOpacity(0.9)
                            : Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        Icon(Icons.timer, color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Text(auction.countdownString,
                            style: const TextStyle(fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w700, fontSize: 12,
                                color: Colors.white)),
                      ]),
                    ),
                  ),
                  // عدد المزايدات
                  if (auction.bidsCount > 0)
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.goldLight.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${auction.bidsCount} 🔥',
                            style: const TextStyle(fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w700, fontSize: 11,
                                color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),

            // ─── المعلومات ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(auction.title,
                      style: AppText.heading3,
                      maxLines: 2,
                      textAlign: TextAlign.right),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('حتى ${auction.maxPriceFormatted}',
                          style: AppText.caption),
                      Row(children: [
                        Icon(Icons.person_outline,
                            size: 14, color: AppTheme.textLight),
                        const SizedBox(width: 4),
                        Text(auction.sellerName ?? 'بائع',
                            style: AppText.caption),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 6),
                  PriceRangeBar(fraction: auction.progressFraction),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
