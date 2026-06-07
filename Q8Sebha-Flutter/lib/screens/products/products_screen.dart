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

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  String? _category;
  final _search = TextEditingController();
  late final AnimationController _animCtrl;

  static const _cats = [
    {'emoji': '✨', 'name': 'الكل',     'slug': null},
    {'emoji': '📿', 'name': 'مسابيح',  'slug': 'masabih'},
    {'emoji': '💎', 'name': 'أحجار',   'slug': 'ahjar'},
    {'emoji': '💍', 'name': 'خواتم',   'slug': 'khawatim'},
    {'emoji': '🟡', 'name': 'كهرب',    'slug': 'kahrab'},
    {'emoji': '🏺', 'name': 'تحف',     'slug': 'tuhaf'},
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      _animCtrl.forward();
    });
  }

  @override
  void dispose() { _animCtrl.dispose(); _search.dispose(); super.dispose(); }

  void _doSearch() =>
      context.read<ProductProvider>().fetchProducts(category: _category, search: _search.text);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          // ─── AppBar ───────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF2D2D50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(children: [
                  // نقاط زخرفية
                  Positioned(top: -20, left: -20,
                    child: Container(width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.gold.withOpacity(0.06),
                      ))),
                  Positioned(bottom: 20, right: -30,
                    child: Container(width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.gold.withOpacity(0.06),
                      ))),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [AppTheme.goldLight, AppTheme.gold],
                          ).createShader(b),
                          child: const Text('Q8Sebha',
                            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800,
                                fontSize: 26, color: Colors.white)),
                        ),
                        Text('اكتشف أجود المسابيح والأحجار',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 13,
                              color: Colors.white.withOpacity(0.6))),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                color: AppTheme.primary,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: TextField(
                    controller: _search,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن منتج...',
                      hintStyle: TextStyle(fontFamily: 'Tajawal', fontSize: 14,
                          color: Colors.white.withOpacity(0.5)),
                      filled: false, border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.6), size: 20),
                    ),
                    onSubmitted: (_) => _doSearch(),
                  ),
                ),
              ),
            ),
          ),

          // ─── فلاتر التصنيف ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              height: 52,
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _cats.length,
                itemBuilder: (_, i) {
                  final c = _cats[i];
                  final slug = c['slug'] as String?;
                  final isSelected = _category == slug;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _category = slug);
                      context.read<ProductProvider>().fetchProducts(
                          category: slug, search: _search.text);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: isSelected ? const LinearGradient(
                          colors: [AppTheme.primary, Color(0xFF2D2D50)],
                        ) : null,
                        color: isSelected ? null : const Color(0xFFF5F5F8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(c['emoji'] as String, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 5),
                        Text(c['name'] as String,
                          style: TextStyle(
                            fontFamily: 'Tajawal', fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                            color: isSelected ? Colors.white : AppTheme.textMid,
                          )),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),

          // ─── عدد النتائج ───────────────────────────────────────────────
          if (!vm.isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text('${vm.products.length} منتج',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13,
                      color: AppTheme.textLight)),
              ),
            ),

          // ─── المحتوى ───────────────────────────────────────────────────
          if (vm.isLoading)
            const SliverFillRemaining(child: LoadingBody())
          else if (vm.products.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(emoji: '🔍', message: 'لا توجد منتجات'))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ProductCard(
                    product: vm.products[i],
                    delay: i * 50,
                  ),
                  childCount: vm.products.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
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
  final int delay;
  const _ProductCard({required this.product, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    final hasImage = product.imageUrls.isNotEmpty;
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06),
                blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // صورة
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(fit: StackFit.expand, children: [
                hasImage
                    ? Image.network(
                        AppConfig.imageUrl(product.imageUrls[0]),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
                // gradient overlay
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                      ),
                    ),
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
                          colors: [AppTheme.goldLight, AppTheme.gold],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(product.badge!,
                        style: const TextStyle(fontFamily: 'Tajawal',
                            fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
              ]),
            ),
          ),

          // معلومات
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(product.name,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                      fontSize: 13, color: AppTheme.textDark,
                    )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // زر إضافة
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                      // السعر
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${product.price.toStringAsFixed(product.price % 1 == 0 ? 0 : 3)} د.ك',
                          style: const TextStyle(
                            fontFamily: 'Tajawal', fontWeight: FontWeight.w800,
                            fontSize: 15, color: AppTheme.primary,
                          )),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFFF0EDE8),
    child: Center(child: Text(product.emoji,
        style: const TextStyle(fontSize: 40))),
  );
}
