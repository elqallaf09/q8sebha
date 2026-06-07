import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List _products = [], _auctions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await APIService.instance.getFavorites();
      _products = r['data']['products'] as List;
      _auctions = r['data']['auctions'] as List;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _removeFavProduct(int productId) async {
    await APIService.instance.toggleFavoriteProduct(productId);
    setState(() => _products.removeWhere((p) => p['id'] == productId));
  }

  Future<void> _removeFavAuction(int auctionId) async {
    await APIService.instance.toggleFavoriteAuction(auctionId);
    setState(() => _auctions.removeWhere((a) => a['id'] == auctionId));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('المفضلة')),
        body: const Center(child: Text('سجّل الدخول لرؤية مفضلاتك',
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 16))),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text('❤️ المفضلة',
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, color: Colors.white)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.gold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: 'المنتجات (${_products.length})'),
            Tab(text: 'المزادات (${_auctions.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : TabBarView(
              controller: _tabs,
              children: [
                _buildProductsList(),
                _buildAuctionsList(),
              ],
            ),
    );
  }

  Widget _buildProductsList() {
    if (_products.isEmpty) return _emptyState('لا يوجد منتجات في المفضلة', '📦');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (_, i) {
          final p = _products[i];
          return _FavCard(
            title: p['name'] ?? '',
            subtitle: '${(p['price'] as num).toStringAsFixed(3)} د.ك',
            emoji: p['emoji'] ?? '📿',
            imageUrl: _firstImage(p['image_urls']),
            onRemove: () => _removeFavProduct(p['id']),
          );
        },
      ),
    );
  }

  Widget _buildAuctionsList() {
    if (_auctions.isEmpty) return _emptyState('لا يوجد مزادات في المفضلة', '🔨');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _auctions.length,
        itemBuilder: (_, i) {
          final a = _auctions[i];
          final price = (a['current_price'] as num?)?.toStringAsFixed(3) ?? '—';
          return _FavCard(
            title: a['title'] ?? '',
            subtitle: 'السعر الحالي: $price د.ك',
            emoji: a['emoji'] ?? '📿',
            imageUrl: _firstImage(a['image_urls']),
            badge: a['status'] == 'active' ? '🟢 نشط' : '🔴 منتهٍ',
            onRemove: () => _removeFavAuction(a['id']),
          );
        },
      ),
    );
  }

  Widget _emptyState(String msg, String emoji) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(emoji, style: const TextStyle(fontSize: 60)),
      const SizedBox(height: 12),
      Text(msg, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16, color: Colors.grey)),
    ]),
  );

  String? _firstImage(dynamic urls) {
    if (urls == null) return null;
    if (urls is List && urls.isNotEmpty) return urls.first as String?;
    if (urls is String && urls.length > 2) {
      final s = urls.replaceAll('[','').replaceAll(']','').replaceAll('"','').trim();
      if (s.isNotEmpty) return s.split(',').first;
    }
    return null;
  }
}

// ─── بطاقة مفضلة ─────────────────────────────────────────────────────────
class _FavCard extends StatelessWidget {
  final String title, subtitle, emoji;
  final String? imageUrl, badge;
  final VoidCallback onRemove;

  const _FavCard({
    required this.title, required this.subtitle, required this.emoji,
    required this.onRemove, this.imageUrl, this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0,2))],
      ),
      child: Row(children: [
        // صورة
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
          child: imageUrl != null && imageUrl!.startsWith('http')
              ? Image.network(imageUrl!, width: 90, height: 90, fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => _placeholder())
              : _placeholder(),
        ),
        // محتوى
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (badge != null) Text(badge!, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11)),
              Text(title, style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: AppTheme.gold,
                  fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        // زر الحذف
        IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red),
          onPressed: onRemove,
          tooltip: 'إزالة من المفضلة',
        ),
      ]),
    );
  }

  Widget _placeholder() => Container(
    width: 90, height: 90,
    color: AppTheme.primary.withOpacity(0.08),
    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 32))),
  );
}
