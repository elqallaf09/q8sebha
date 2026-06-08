import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/product_provider.dart';
import '../../models/models.dart';
import '../../main.dart';
import '../../config/app_config.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/responsive.dart';
import '../../services/api_service.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with TickerProviderStateMixin {
  String? _category;    // الفئة الرئيسية المختارة (slug)
  String? _subCategory; // الفئة الفرعية المختارة (slug)
  final _search = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _searchFocused = false;
  late final AnimationController _headerAnim;
  late final AnimationController _gridAnim;

  // فلتر متقدم
  double? _minPrice, _maxPrice;
  String? _sortBy; // 'price_asc' | 'price_desc' | 'newest'
  bool get _hasFilter => _minPrice != null || _maxPrice != null || _sortBy != null;

  // ─── هيكل الفئات الهرمي ─────────────────────────────────────────────────
  static const _cats = <Map<String, dynamic>>[
    {'name':'الكل',         'slug':null,          'color':0xFF1A1A2E,'subs':null},
    {'name':'مسابيح',       'slug':'masabih',     'color':0xFF6B4226,'subs':[
      {'name':'كهرب',        'slug':'masabih-kahrab'},
      {'name':'مصنع',        'slug':'masabih-masna3'},
      {'name':'فاتوران',     'slug':'masabih-faturan'},
      {'name':'بكلايت',      'slug':'masabih-bakalait'},
      {'name':'كاست',        'slug':'masabih-cast'},
      {'name':'قلاليث',      'slug':'masabih-qalaliath'},
      {'name':'صب قديم',     'slug':'masabih-sub-qadim'},
      {'name':'تراب كهرب',   'slug':'masabih-turab'},
      {'name':'مستكة',       'slug':'masabih-mastaka'},
    ]},
    {'name':'تحف',          'slug':'tuhaf',       'color':0xFF4A148C,'subs':null},
    {'name':'خواتم',        'slug':'khawatim',    'color':0xFF880E4F,'subs':null},
    {'name':'صخور',         'slug':'sukhur',      'color':0xFF546E7A,'subs':null},
    {'name':'أحجار كريمة',  'slug':'ahjar-karima','color':0xFF1565C0,'subs':[
      {'name':'ألماس',        'slug':'ahjar-almas'},
      {'name':'ياقوت أحمر',  'slug':'ahjar-ruby'},
      {'name':'ياقوت أزرق',  'slug':'ahjar-sapphire'},
      {'name':'زمرد',         'slug':'ahjar-zumurrud'},
      {'name':'جمشت',         'slug':'ahjar-jamst'},
      {'name':'عقيق',         'slug':'ahjar-aqeeq'},
      {'name':'فيروز',        'slug':'ahjar-fayruz'},
      {'name':'لازورد',       'slug':'ahjar-lazurd'},
      {'name':'توباز',        'slug':'ahjar-topaz'},
      {'name':'زبرجد',        'slug':'ahjar-zabarjad'},
      {'name':'مرجان',        'slug':'ahjar-marjan'},
      {'name':'لؤلؤ',         'slug':'ahjar-lulu'},
      {'name':'أوبال',        'slug':'ahjar-opal'},
      {'name':'أكوامارين',    'slug':'ahjar-aquamarine'},
      {'name':'سيترين',       'slug':'ahjar-citrine'},
      {'name':'تنزانيت',      'slug':'ahjar-tanzanite'},
      {'name':'تورمالين',     'slug':'ahjar-tourmaline'},
      {'name':'حجر القمر',    'slug':'ahjar-moonstone'},
      {'name':'كوارتز وردي',  'slug':'ahjar-rose-quartz'},
      {'name':'كوارتز دخاني', 'slug':'ahjar-smoky-quartz'},
      {'name':'عقيق ناري',    'slug':'ahjar-fire-agate'},
      {'name':'كارنيليان',    'slug':'ahjar-carnelian'},
      {'name':'أونيكس',       'slug':'ahjar-onyx'},
      {'name':'مالاشيت',      'slug':'ahjar-malachite'},
      {'name':'لابرادوريت',   'slug':'ahjar-labradorite'},
      {'name':'أوبسيديان',    'slug':'ahjar-obsidian'},
      {'name':'حجر الشمس',    'slug':'ahjar-sunstone'},
      {'name':'كهرمان',       'slug':'ahjar-kahramaan'},
      {'name':'رودونيت',      'slug':'ahjar-rhodonite'},
      {'name':'هيماتيت',      'slug':'ahjar-hematite'},
      {'name':'يشم',          'slug':'ahjar-jade'},
      {'name':'عين النمر',    'slug':'ahjar-tiger-eye'},
      {'name':'جارنت',        'slug':'ahjar-garnet'},
      {'name':'أباتيت',       'slug':'ahjar-apatite'},
      {'name':'أزوريت',       'slug':'ahjar-azurite'},
      {'name':'كريسوكولا',    'slug':'ahjar-chrysocolla'},
      {'name':'رودوكروزيت',   'slug':'ahjar-rhodochrosite'},
      {'name':'حجر الدم',     'slug':'ahjar-bloodstone'},
      {'name':'أم اللؤلؤ',    'slug':'ahjar-mother-pearl'},
      {'name':'كوارتز روتيل', 'slug':'ahjar-rutile-quartz'},
      {'name':'كوارتز فراولة','slug':'ahjar-strawberry-quartz'},
    ]},
  ];

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _gridAnim   = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      _headerAnim.forward();
      Future.delayed(const Duration(milliseconds: 300), () => _gridAnim.forward());
    });
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _gridAnim.dispose();
    _search.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // الـ slug الفعّال للفلترة: الفرعي أولاً ثم الرئيسي
  String? get _activeSlug => _subCategory ?? _category;

  void _doSearch() =>
      context.read<ProductProvider>().fetchProducts(category: _activeSlug, search: _search.text);

  void _selectCat(String? slug) {
    HapticFeedback.lightImpact();
    setState(() { _category = slug; _subCategory = null; });
    context.read<ProductProvider>().fetchProducts(category: slug, search: _search.text);
  }

  void _selectSubCat(String? slug) {
    HapticFeedback.selectionClick();
    setState(() => _subCategory = slug);
    context.read<ProductProvider>().fetchProducts(
        category: slug ?? _category, search: _search.text);
  }

  // هل الفئة الرئيسية المختارة لديها فئات فرعية؟
  List<Map<String,dynamic>>? get _currentSubs {
    if (_category == null) return null;
    for (final c in _cats) {
      if (c['slug'] == _category) {
        final subs = c['subs'] as List?;
        if (subs != null && subs.isNotEmpty) {
          return subs.cast<Map<String,dynamic>>();
        }
      }
    }
    return null;
  }

  void _showFilterSheet(BuildContext context) {
    double? tempMin = _minPrice;
    double? tempMax = _maxPrice;
    String? tempSort = _sortBy;
    final minCtrl = TextEditingController(text: _minPrice?.toStringAsFixed(0) ?? '');
    final maxCtrl = TextEditingController(text: _maxPrice?.toStringAsFixed(0) ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20,
              MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // handle
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('تصفية متقدمة',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800,
                    fontSize: 18, color: AppTheme.textDark)),
              const SizedBox(height: 20),

              // نطاق السعر
              const Align(alignment: Alignment.centerRight,
                child: Text('نطاق السعر (د.ك)',
                  style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                      fontSize: 14, color: AppTheme.textMid))),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: minCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'من',
                      hintStyle: const TextStyle(fontFamily: 'Tajawal'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) => tempMin = double.tryParse(v),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('—', style: TextStyle(fontSize: 18, color: AppTheme.textMid)),
                ),
                Expanded(
                  child: TextField(
                    controller: maxCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'إلى',
                      hintStyle: const TextStyle(fontFamily: 'Tajawal'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) => tempMax = double.tryParse(v),
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              // الترتيب
              const Align(alignment: Alignment.centerRight,
                child: Text('الترتيب',
                  style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                      fontSize: 14, color: AppTheme.textMid))),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                for (final opt in [
                  ('الأحدث', 'newest'),
                  ('السعر: الأقل', 'price_asc'),
                  ('السعر: الأعلى', 'price_desc'),
                ])
                  GestureDetector(
                    onTap: () => setLocal(() => tempSort = opt.$2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: tempSort == opt.$2 ? AppTheme.primary : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: tempSort == opt.$2 ? AppTheme.primary : Colors.grey.shade300),
                      ),
                      child: Text(opt.$1,
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tempSort == opt.$2 ? Colors.white : AppTheme.textMid)),
                    ),
                  ),
              ]),
              const SizedBox(height: 24),

              // أزرار
              Row(children: [
                // إعادة تعيين
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() { _minPrice = null; _maxPrice = null; _sortBy = null; });
                      Navigator.pop(context);
                      _doSearch();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.textMid),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('إعادة تعيين',
                      style: TextStyle(fontFamily: 'Tajawal', color: AppTheme.textMid)),
                  ),
                ),
                const SizedBox(width: 12),
                // تطبيق
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _minPrice = tempMin;
                        _maxPrice = tempMax;
                        _sortBy = tempSort;
                      });
                      Navigator.pop(context);
                      _applyFilter();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('تطبيق',
                      style: TextStyle(fontFamily: 'Tajawal', color: Colors.white,
                          fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _applyFilter() {
    final vm = context.read<ProductProvider>();
    // نبدأ من القائمة الأصلية
    vm.resetFilter();
    var list = List.of(vm.products);

    // فلتر السعر
    if (_minPrice != null) list = list.where((p) => p.price >= _minPrice!).toList();
    if (_maxPrice != null) list = list.where((p) => p.price <= _maxPrice!).toList();

    // ترتيب
    if (_sortBy == 'price_asc')  list.sort((a, b) => a.price.compareTo(b.price));
    if (_sortBy == 'price_desc') list.sort((a, b) => b.price.compareTo(a.price));
    if (_sortBy == 'newest')     list.sort((a, b) => b.id.compareTo(a.id));

    if (_hasFilter) vm.setFilteredProducts(list);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F0),
      body: CustomScrollView(
        controller: _scrollCtrl,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(),
          _buildSearchBar(),
          _buildCategories(),
          _buildResultCount(vm),
          _buildGrid(vm),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() => SliverAppBar(
    expandedHeight: 160,
    floating: false,
    pinned: true,
    elevation: 0,
    backgroundColor: const Color(0xFF1A1A2E),
    systemOverlayStyle: SystemUiOverlayStyle.light,
    flexibleSpace: FlexibleSpaceBar(
      collapseMode: CollapseMode.parallax,
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F1E), Color(0xFF1A1A2E), Color(0xFF252545)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(children: [
          // دوائر زخرفية
          Positioned(top: -40, right: -40,
            child: Container(width: 180, height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppTheme.gold.withOpacity(0.07)))),
          Positioned(bottom: -20, left: -20,
            child: Container(width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03)))),
          Positioned(top: 50, left: 60,
            child: Container(width: 60, height: 60,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppTheme.gold.withOpacity(0.04)))),
          // محتوى
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // أيقونة السلة
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined,
                            color: Colors.white70, size: 20),
                      ),
                      // الشعار
                      Row(children: [
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [AppTheme.goldLight, AppTheme.gold],
                          ).createShader(b),
                          child: const Text('مسابيح لايقر',
                            style: TextStyle(fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w900, fontSize: 24,
                                color: Colors.white, letterSpacing: 0.5)),
                        ),
                        const SizedBox(width: 6),
                        const Text('📿', style: TextStyle(fontSize: 20)),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    ),
  );

  // ─── Search ────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() => SliverToBoxAdapter(
    child: Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Focus(
        onFocusChange: (v) => setState(() => _searchFocused = v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: _searchFocused
                ? Colors.white
                : Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _searchFocused
                  ? AppTheme.gold
                  : Colors.white.withOpacity(0.15),
              width: _searchFocused ? 1.5 : 1,
            ),
            boxShadow: _searchFocused ? [
              BoxShadow(color: AppTheme.gold.withOpacity(0.15),
                  blurRadius: 12, offset: const Offset(0, 4)),
            ] : [],
          ),
          child: TextField(
            controller: _search,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Tajawal', fontSize: 14,
              color: _searchFocused ? AppTheme.textDark : Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'ابحث عن منتج...',
              hintStyle: TextStyle(
                fontFamily: 'Tajawal', fontSize: 14,
                color: _searchFocused
                    ? Colors.grey.shade400
                    : Colors.white.withOpacity(0.45),
              ),
              filled: false, border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: GestureDetector(
                onTap: _doSearch,
                child: Icon(Icons.search_rounded,
                  color: _searchFocused ? AppTheme.gold : Colors.white60, size: 22),
              ),
              suffixIcon: _search.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _search.clear();
                        _doSearch();
                        setState(() {});
                      },
                      child: Icon(Icons.close_rounded,
                        color: _searchFocused ? Colors.grey : Colors.white60, size: 18),
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _doSearch(),
          ),
        ),
      ),
    ),
  );

  // ─── Categories ────────────────────────────────────────────────────────────
  Widget _buildCategories() {
    final subs = _currentSubs;
    final parentColor = _category != null
        ? Color(_cats.firstWhere((c) => c['slug'] == _category,
              orElse: () => _cats[0])['color'] as int)
        : const Color(0xFF1A1A2E);

    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        child: Column(children: [
          // ─── الصف الأول: الفئات الرئيسية ──────────────────────────────
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _cats.length,
              itemBuilder: (_, i) {
                final c = _cats[i];
                final slug = c['slug'] as String?;
                final isSelected = _category == slug;
                final catColor = Color(c['color'] as int);
                final hasSubs = (c['subs'] as List?)?.isNotEmpty == true;
                return GestureDetector(
                  onTap: () => _selectCat(slug),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: isSelected ? LinearGradient(
                        colors: [catColor, catColor.withOpacity(0.75)],
                      ) : null,
                      color: isSelected ? null : const Color(0xFFF5F4F1),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isSelected ? [BoxShadow(
                          color: catColor.withOpacity(0.35),
                          blurRadius: 8, offset: const Offset(0, 3))] : [],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(c['name'] as String,
                        style: TextStyle(
                          fontFamily: 'Tajawal', fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.textMid,
                        )),
                      // مؤشر الفئات الفرعية
                      if (hasSubs) ...[
                        const SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_down,
                          size: 14,
                          color: isSelected ? Colors.white70 : AppTheme.textMid,
                        ),
                      ],
                    ]),
                  ),
                );
              },
            ),
          ),

          // ─── الصف الثاني: الفئات الفرعية (يظهر فقط عند الاختيار) ──────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeIn,
            crossFadeState: subs != null
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: subs != null ? Container(
              color: parentColor.withOpacity(0.04),
              child: Column(children: [
                Container(height: 1, color: parentColor.withOpacity(0.12)),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: subs.length + 1, // +1 for "الكل"
                    itemBuilder: (_, i) {
                      final isAll = i == 0;
                      final slug = isAll ? null : subs[i-1]['slug'] as String;
                      final name = isAll ? 'الكل' : subs[i-1]['name'] as String;
                      final isSelected = _subCategory == slug;
                      return GestureDetector(
                        onTap: () => _selectSubCat(slug),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? parentColor
                                : parentColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? parentColor
                                  : parentColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(name,
                            style: TextStyle(
                              fontFamily: 'Tajawal', fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : parentColor.withOpacity(0.85),
                            )),
                        ),
                      );
                    },
                  ),
                ),
              ]),
            ) : const SizedBox.shrink(),
          ),

          Container(height: 1, color: const Color(0xFFF0EEE9)),
        ]),
      ),
    );
  }

  // ─── Result Count ──────────────────────────────────────────────────────────
  Widget _buildResultCount(ProductProvider vm) => SliverToBoxAdapter(
    child: AnimatedOpacity(
      opacity: vm.isLoading ? 0 : 1,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // زر الفلتر
            GestureDetector(
              onTap: () => _showFilterSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _hasFilter ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _hasFilter ? AppTheme.primary : const Color(0xFFE8E6E0)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.tune_rounded, size: 14, color: _hasFilter ? Colors.white : AppTheme.textMid),
                  const SizedBox(width: 4),
                  Text(_hasFilter ? 'تصفية ✓' : 'تصفية',
                    style: TextStyle(fontFamily: 'Tajawal',
                        fontSize: 12, color: _hasFilter ? Colors.white : AppTheme.textMid)),
                ]),
              ),
            ),
            // العدد
            RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'Tajawal'),
                children: [
                  TextSpan(
                    text: '${vm.products.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15,
                      color: AppTheme.primary,
                    ),
                  ),
                  const TextSpan(
                    text: ' منتج متاح',
                    style: TextStyle(fontSize: 13, color: AppTheme.textLight),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // ─── Grid ──────────────────────────────────────────────────────────────────
  Widget _buildGrid(ProductProvider vm) {
    if (vm.isLoading) {
      return SliverFillRemaining(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            SizedBox(
              width: 40, height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: const AlwaysStoppedAnimation(AppTheme.gold),
                backgroundColor: AppTheme.gold.withOpacity(0.15),
              ),
            ),
            const SizedBox(height: 16),
            const Text('جارٍ التحميل...', style: TextStyle(
                fontFamily: 'Tajawal', fontSize: 14, color: AppTheme.textLight)),
          ],
        ),
      );
    }

    if (vm.products.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🔍', style: TextStyle(fontSize: 44)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('لا توجد منتجات',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                    fontSize: 18, color: AppTheme.textDark)),
              const SizedBox(height: 8),
              const Text('جرّب تغيير الفلتر أو البحث',
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 13,
                    color: AppTheme.textLight)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _ProductCard(product: vm.products[i], index: i),
          childCount: vm.products.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: R.cols(context),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: R.cardRatio(context),
        ),
      ),
    );
  }
}

// ─── بطاقة المنتج ─────────────────────────────────────────────────────────────
class _ProductCard extends StatefulWidget {
  final Product product;
  final int index;
  const _ProductCard({required this.product, this.index = 0});
  @override State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  bool _liked = false;
  bool _favLoading = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this,
        duration: Duration(milliseconds: 400 + widget.index * 60));
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) {
        _anim.forward();
        _checkFav();
      }
    });
  }

  Future<void> _checkFav() async {
    try {
      final isFav = await APIService.instance.checkFavoriteProduct(widget.product.id);
      if (mounted) setState(() => _liked = isFav);
    } catch (_) {}
  }

  Future<void> _toggleFav() async {
    if (_favLoading) return;
    HapticFeedback.lightImpact();
    setState(() { _favLoading = true; _liked = !_liked; });
    try {
      await APIService.instance.toggleFavoriteProduct(widget.product.id);
    } catch (_) {
      if (mounted) setState(() => _liked = !_liked); // ارجع للحالة السابقة
    }
    if (mounted) setState(() => _favLoading = false);
  }

  void _shareProduct() {
    final p = widget.product;
    final price = p.price.toStringAsFixed(p.price % 1 == 0 ? 0 : 3);
    Share.share('🛒 ${p.name}\n💰 السعر: $price د.ك\n\nتسوّق معنا على تطبيق Q8Sebha 📿');
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final hasImage = p.imageUrls.isNotEmpty;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id))),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06),
                    blurRadius: 16, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // ─── صورة ───────────────────────────────────────────────────
              Expanded(
                flex: 11,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(fit: StackFit.expand, children: [
                    // الصورة
                    hasImage
                        ? Image.network(
                            AppConfig.imageUrl(p.imageUrls[0]),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),

                    // gradient
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.45),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // badge
                    if (p.badge != null)
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.goldLight, AppTheme.gold],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: AppTheme.gold.withOpacity(0.4),
                                  blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Text(p.badge!,
                            style: const TextStyle(fontFamily: 'Tajawal',
                                fontSize: 9, fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        ),
                      ),

                    // زر المفضلة + مشاركة
                    Positioned(
                      top: 8, left: 8,
                      child: Column(children: [
                        GestureDetector(
                          onTap: _toggleFav,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: _liked
                                  ? Colors.red.shade400
                                  : Colors.black.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: _favLoading
                                ? const SizedBox(width: 14, height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                                : Icon(_liked ? Icons.favorite : Icons.favorite_border,
                                    color: Colors.white, size: 14),
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _shareProduct,
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.share_rounded,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ]),
                    ),

                    // السعر فوق الصورة
                    Positioned(
                      bottom: 8, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.gold.withOpacity(0.5), width: 0.8),
                        ),
                        child: Text(
                          '${p.price.toStringAsFixed(p.price % 1 == 0 ? 0 : 3)} د.ك',
                          style: const TextStyle(
                            fontFamily: 'Tajawal', fontWeight: FontWeight.w800,
                            fontSize: 12, color: AppTheme.goldLight,
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),

              // ─── معلومات ────────────────────────────────────────────────
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // الاسم
                      Text(p.name,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                          fontSize: 13, color: AppTheme.textDark,
                          height: 1.3,
                        )),

                      // صف الزر والمخزون
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // زر إضافة للسلة
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              Navigator.push(context,
                                MaterialPageRoute(builder: (_) =>
                                    ProductDetailScreen(productId: p.id)));
                            },
                            child: Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1A1A2E), Color(0xFF2D2D50)],
                                ),
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1A1A2E).withOpacity(0.3),
                                    blurRadius: 6, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: const Icon(Icons.arrow_forward_ios_rounded,
                                  color: Colors.white, size: 14),
                            ),
                          ),

                          // مخزون
                          if (p.stock <= 3 && p.stock > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('${p.stock} فقط',
                                style: TextStyle(
                                  fontFamily: 'Tajawal', fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange.shade700,
                                )),
                            )
                          else if (p.stock == 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('نفد',
                                style: TextStyle(
                                  fontFamily: 'Tajawal', fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red.shade400,
                                )),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [const Color(0xFFEDE8DF), const Color(0xFFF5F1EB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text(widget.product.emoji,
          style: const TextStyle(fontSize: 42)),
    ),
  );
}
