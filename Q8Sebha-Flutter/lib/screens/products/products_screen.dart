import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/models.dart';
import '../../main.dart';
import '../../config/app_config.dart';
import '../../widgets/common_widgets.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with SingleTickerProviderStateMixin {
  String? _category;
  final _search = TextEditingController();
  late final AnimationController _animCtrl;

  static const _cats = [
    {'emoji': '✨', 'name': 'الكل',    'slug': null},
    {'emoji': '📿', 'name': 'مسابيح', 'slug': 'misbaha'},
    {'emoji': '💎', 'name': 'أحجار',  'slug': 'gemstones'},
    {'emoji': '💍', 'name': 'خواتم',  'slug': 'rings'},
    {'emoji': '🏺', 'name': 'تحف',    'slug': 'antiques'},
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _search.dispose();
    super.dispose();
  }

  void _doSearch() =>
      context.read<ProductProvider>().fetchProducts(category: _category, search: _search.text);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          // ─── AppBar ─────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppTheme.gradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(children: [
                                Text('📿', style: TextStyle(fontSize: 14)),
                                SizedBox(width: 6),
                                Text('Q8Sebha',
                                    style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                                        fontSize: 14, color: Colors.white)),
                              ]),
                            ),
                            const Text('مرحباً بك 👋',
                                style: TextStyle(fontFamily: 'Tajawal', fontSize: 14,
                                    color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text('اكتشف أجمل المسابيح والأحجار الكريمة',
                            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                                fontSize: 18, color: Colors.white),
                            textAlign: TextAlign.right),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                color: AppTheme.primary,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _search,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج...',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search, color: AppTheme.primary),
                      onPressed: _doSearch,
                    ),
                    prefixIcon: _search.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () { _search.clear(); _doSearch(); })
                        : null,
                  ),
                  onSubmitted: (_) => _doSearch(),
                ),
              ),
            ),
          ),

          // ─── فلتر الفئات ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _cats.length,
                itemBuilder: (_, i) {
                  final c = _cats[i];
                  final selected = _category == c['slug'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _category = c['slug'] as String?);
                      context.read<ProductProvider>().fetchProducts(category: _category);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: selected ? AppTheme.gradient : null,
                        color: selected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selected ? Colors.transparent : Colors.grey.shade200,
                        ),
                        boxShadow: selected ? [
                          BoxShadow(color: AppTheme.primary.withOpacity(0.3),
                              blurRadius: 8, offset: const Offset(0, 3))
                        ] : [],
                      ),
                      child: Row(children: [
                        Text(c['emoji'] as String, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 5),
                        Text(c['name'] as String,
                            style: TextStyle(
                              fontFamily: 'Tajawal', fontWeight: FontWeight.w600,
                              fontSize: 13, color: selected ? Colors.white : AppTheme.textMid,
                            )),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),

          // ─── عدد النتائج ─────────────────────────────────────────────
          if (!vm.isLoading && vm.products.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Text('${vm.products.length} منتج',
                    style: AppText.caption, textAlign: TextAlign.right),
              ),
            ),

          // ─── المحتوى ─────────────────────────────────────────────────
          if (vm.isLoading)
            const SliverFillRemaining(child: LoadingBody())
          else if (vm.products.isEmpty)
            const SliverFillRemaining(child: EmptyState(emoji: '📦', message: 'لا توجد منتجات'))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.70,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ProductCard(product: vm.products[i]),
                  childCount: vm.products.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── بطاقة المنتج ─────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id))),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── الصورة
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: product.imageUrls.isEmpty
                      ? Container(
                          color: const Color(0xFFF0EDE8),
                          child: Center(
                            child: Text(product.emoji,
                                style: const TextStyle(fontSize: 52)),
                          ))
                      : Image.network(
                          AppConfig.imageUrl(product.primaryImage),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (_, child, progress) => progress == null
                              ? child
                              : Container(
                                  color: const Color(0xFFF0EDE8),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        color: AppTheme.primary, strokeWidth: 2),
                                  )),
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFF0EDE8),
                            child: Center(
                              child: Text(product.emoji,
                                  style: const TextStyle(fontSize: 52)),
                            )),
                        ),
                ),
                // badge
                if (product.badge != null)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFE53935), Color(0xFFC62828)]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(product.badge!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                    ),
                  ),
                // تدرج سفلي للنص
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(0)),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.15), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── المعلومات
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(product.name,
                    style: AppText.heading3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(product.priceFormatted,
                          style: AppText.price.copyWith(fontSize: 13)),
                    ),
                    Text(product.emoji, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
