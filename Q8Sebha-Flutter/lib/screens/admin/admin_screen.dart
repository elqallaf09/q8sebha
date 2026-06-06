import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../main.dart';
import '../../widgets/common_widgets.dart';

// ─── لوحة الأدمن الرئيسية ────────────────────────────────────────────────
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('لوحة الأدمن ⚙️'),
      bottom: TabBar(
        controller: _tabs,
        indicatorColor: Colors.white,
        tabs: const [
          Tab(text: 'المنتجات', icon: Icon(Icons.shopping_bag_outlined)),
          Tab(text: 'إضافة منتج', icon: Icon(Icons.add_box_outlined)),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabs,
      children: [
        const _ProductsTab(),
        _AddProductTab(onAdded: () => _tabs.animateTo(0)),
      ],
    ),
  );
}

// ─── تبويب: قائمة المنتجات ───────────────────────────────────────────────
class _ProductsTab extends StatefulWidget {
  const _ProductsTab();
  @override State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _products = await APIService.instance.products(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(Product p) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text('حذف "${p.name}"؟', textAlign: TextAlign.right,
        style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700)),
      content: const Text('لا يمكن التراجع عن هذا الإجراء',
        textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Tajawal')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('حذف')),
      ],
    ));
    if (ok != true) return;
    try {
      await APIService.instance.request('DELETE', '/products/${p.id}');
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Tajawal'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBody();
    if (_products.isEmpty) return const EmptyState(emoji: '📦', message: 'لا توجد منتجات بعد');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _products.length,
        itemBuilder: (_, i) {
          final p = _products[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: Text(p.emoji ?? '📿', style: const TextStyle(fontSize: 22)),
              ),
              title: Text(p.name,
                textAlign: TextAlign.right,
                style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Text(
                '${p.priceFormatted} — مخزون: ${p.stock}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.grey)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _delete(p),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── تبويب: إضافة منتج ───────────────────────────────────────────────────
class _AddProductTab extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddProductTab({required this.onAdded});
  @override State<_AddProductTab> createState() => _AddProductTabState();
}

class _AddProductTabState extends State<_AddProductTab> {
  final _name    = TextEditingController();
  final _desc    = TextEditingController();
  final _price   = TextEditingController();
  final _stock   = TextEditingController(text: '1');
  final _beads   = TextEditingController();
  final _weight  = TextEditingController();
  final _material= TextEditingController();

  String _emoji      = '📿';
  int?   _categoryId;
  List<Map<String,dynamic>> _categories = [];

  final _picker = ImagePicker();
  final List<XFile>     _files    = [];
  final List<Uint8List> _previews = [];

  bool    _loading = false;
  String? _error;
  String? _success;

  static const _emojis = ['📿','💎','🪬','🧿','⚜️','🏅','💍','🌿'];

  @override
  void initState() { super.initState(); _loadCategories(); }

  Future<void> _loadCategories() async {
    try {
      final r = await APIService.instance.request('GET', '/admin/categories', auth: true);
      final list = r['data'] as List? ?? [];
      setState(() => _categories = list.map((e) => Map<String,dynamic>.from(e as Map)).toList());
      if (_categories.isNotEmpty) _categoryId = _categories.first['id'] as int;
    } catch (_) {}
  }

  Future<void> _pickImages() async {
    if (_files.length >= 6) return;
    final picked = await _picker.pickMultiImage(imageQuality: 80, limit: 6 - _files.length);
    for (final f in picked) {
      final b = await f.readAsBytes();
      setState(() { _files.add(f); _previews.add(b); });
    }
  }

  Future<void> _submit() async {
    if (_name.text.isEmpty || _price.text.isEmpty || _categoryId == null) {
      setState(() => _error = 'اسم المنتج والسعر والفئة مطلوبة'); return;
    }
    final price = double.tryParse(_price.text);
    if (price == null || price <= 0) {
      setState(() => _error = 'سعر غير صحيح'); return;
    }

    setState(() { _loading = true; _error = null; _success = null; });
    try {
      List<String> imageUrls = [];
      if (_files.isNotEmpty) imageUrls = await APIService.instance.uploadImages(_files);

      await APIService.instance.request('POST', '/products', body: {
        'category_id': _categoryId,
        'name':         _name.text,
        'description':  _desc.text,
        'price':        price,
        'stock':        int.tryParse(_stock.text) ?? 1,
        'bead_count':   int.tryParse(_beads.text),
        'weight_grams': double.tryParse(_weight.text),
        'material':     _material.text.isEmpty ? null : _material.text,
        'emoji':        _emoji,
        'image_urls':   imageUrls,
      });

      setState(() { _success = '✅ تم إضافة المنتج بنجاح'; });
      _name.clear(); _desc.clear(); _price.clear();
      _stock.text = '1'; _beads.clear(); _weight.clear(); _material.clear();
      _files.clear(); _previews.clear();
      widget.onAdded();
    } on APIError catch (e) { setState(() => _error = e.message); }
    catch (e) { setState(() => _error = e.toString()); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [

      // ─── صور المنتج ───────────────────────────────────────
      const Text('صور المنتج', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 10),
      SizedBox(
        height: 100,
        child: ListView(scrollDirection: Axis.horizontal, reverse: true, children: [
          if (_files.length < 6)
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 88, height: 88,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.primary.withOpacity(0.06),
                ),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primary, size: 28),
                  SizedBox(height: 4),
                  Text('أضف صورة', style: TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: AppTheme.primary)),
                ]),
              ),
            ),
          ..._previews.asMap().entries.map((e) => Stack(children: [
            Container(
              width: 88, height: 88,
              margin: const EdgeInsets.only(left: 8, top: 4, right: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(image: MemoryImage(e.value), fit: BoxFit.cover),
              ),
            ),
            Positioned(top: 0, right: 0, child: GestureDetector(
              onTap: () => setState(() { _files.removeAt(e.key); _previews.removeAt(e.key); }),
              child: Container(
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                padding: const EdgeInsets.all(3),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            )),
          ])).toList().reversed.toList(),
        ]),
      ),
      const SizedBox(height: 16),

      // ─── الإيموجي ─────────────────────────────────────────
      const Text('أيقونة المنتج', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: _emojis.map((e) => GestureDetector(
        onTap: () => setState(() => _emoji = e),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _emoji == e ? AppTheme.primary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(e, style: const TextStyle(fontSize: 22)),
        ),
      )).toList()),
      const SizedBox(height: 16),

      // ─── الفئة ────────────────────────────────────────────
      if (_categories.isNotEmpty) ...[
        const Text('الفئة', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _categoryId,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true, fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: _categories.map((c) => DropdownMenuItem<int>(
            value: c['id'] as int,
            child: Text(c['name'] as String? ?? '', textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14)),
          )).toList(),
          onChanged: (v) => setState(() => _categoryId = v),
        ),
        const SizedBox(height: 12),
      ],

      // ─── الحقول ───────────────────────────────────────────
      Q8Field(hint: 'اسم المنتج *', controller: _name, icon: Icons.title),
      const SizedBox(height: 12),
      Q8Field(hint: 'الوصف', controller: _desc, icon: Icons.description),
      const SizedBox(height: 12),
      Q8Field(hint: 'السعر بالدينار الكويتي *', controller: _price, icon: Icons.attach_money, keyboard: TextInputType.number),
      const SizedBox(height: 12),
      Q8Field(hint: 'الكمية المتاحة', controller: _stock, icon: Icons.inventory_2_outlined, keyboard: TextInputType.number),
      const SizedBox(height: 12),
      Q8Field(hint: 'عدد الحبات', controller: _beads, icon: Icons.format_list_numbered, keyboard: TextInputType.number),
      const SizedBox(height: 12),
      Q8Field(hint: 'الوزن (جرام)', controller: _weight, icon: Icons.scale, keyboard: TextInputType.number),
      const SizedBox(height: 12),
      Q8Field(hint: 'الخامة (عقيق، كهرمان...)', controller: _material, icon: Icons.diamond_outlined),
      const SizedBox(height: 20),

      if (_error   != null) ErrorBanner(_error!),
      if (_success != null) Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
        child: Text(_success!, textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Tajawal', color: Colors.green, fontWeight: FontWeight.w600)),
      ),

      Q8Button(label: 'إضافة المنتج 📦', isLoading: _loading, onTap: _submit),
      const SizedBox(height: 20),
    ]),
  );
}
