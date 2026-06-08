import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../../config/app_config.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('لوحة التحكم 🛠️'),
      bottom: TabBar(
        controller: _tabs,
        indicatorColor: AppTheme.goldLight,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 12),
        tabs: const [
          Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'إحصائيات'),
          Tab(icon: Icon(Icons.inventory_2, size: 18), text: 'المنتجات'),
          Tab(icon: Icon(Icons.people, size: 18), text: 'المستخدمون'),
          Tab(icon: Icon(Icons.gavel, size: 18), text: 'المزادات'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabs,
      children: const [
        _StatsTab(),
        _ProductsTab(),
        _UsersTab(),
        _AuctionsTab(),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════
// TAB 1: الإحصائيات
// ═══════════════════════════════════════════════
class _StatsTab extends StatefulWidget {
  const _StatsTab();
  @override State<_StatsTab> createState() => _StatsTabState();
}
class _StatsTabState extends State<_StatsTab> {
  Map<String,dynamic>? _stats;
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await APIService.instance.adminStats();
      setState(() { _stats = r['data']; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingBody();
    if (_stats == null) return const EmptyState(emoji: '⚠️', message: 'تعذّر تحميل الإحصائيات');
    final s = _stats!;
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(child: _StatCard('المستخدمون', '${s['users']??0}', Icons.people, AppTheme.primary)),
            const SizedBox(width:12),
            Expanded(child: _StatCard('المنتجات', '${s['products']??0}', Icons.inventory_2, Colors.teal)),
          ]),
          const SizedBox(height:12),
          Row(children: [
            Expanded(child: _StatCard('المزادات', '${s['auctions']??0}', Icons.gavel, Colors.orange)),
            const SizedBox(width:12),
            Expanded(child: _StatCard('الطلبات', '${s['orders']??0}', Icons.shopping_bag, Colors.purple)),
          ]),
          const SizedBox(height:12),
          Row(children: [
            Expanded(child: _StatCard('نشطة', '${s['active_auctions']??0}', Icons.circle, Colors.green)),
            const SizedBox(width:12),
            Expanded(child: _StatCard('محظورون', '${s['banned_users']??0}', Icons.block, Colors.red)),
          ]),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 10, offset: const Offset(0,4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
        Text(value, style: TextStyle(fontFamily:'Tajawal', fontWeight:FontWeight.w800, fontSize:28, color:color)),
      ]),
      const SizedBox(height:8),
      Text(title, style: AppText.caption),
    ]),
  );
}

// ═══════════════════════════════════════════════
// TAB 2: المنتجات
// ═══════════════════════════════════════════════
class _ProductsTab extends StatefulWidget {
  const _ProductsTab();
  @override State<_ProductsTab> createState() => _ProductsTabState();
}
class _ProductsTabState extends State<_ProductsTab> {
  List<dynamic> _products = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await APIService.instance.products();
      setState(() { _products = r.map((p) => {
        'id': p.id, 'name': p.name, 'price': p.price,
        'emoji': p.emoji, 'image_urls': p.imageUrls,
      }).toList(); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('حذف المنتج', textAlign:TextAlign.right,
          style:TextStyle(fontFamily:'Tajawal', fontWeight:FontWeight.w700, color:Colors.red)),
      content: const Text('هل أنت متأكد؟', textAlign:TextAlign.right,
          style:TextStyle(fontFamily:'Tajawal')),
      actions: [
        TextButton(onPressed:()=>Navigator.pop(context,false), child:const Text('إلغاء')),
        ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:Colors.red),
          onPressed:()=>Navigator.pop(context,true), child:const Text('حذف')),
      ],
    ));
    if (ok==true) { await APIService.instance.adminDeleteProduct(id); _load(); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bg,
    body: _loading ? const LoadingBody()
        : _products.isEmpty ? const EmptyState(emoji:'📦', message:'لا توجد منتجات')
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12,12,12,100),
              itemCount: _products.length,
              itemBuilder: (_, i) {
                final p = _products[i];
                final urls = p['image_urls'] as List? ?? [];
                return Container(
                  margin: const EdgeInsets.only(bottom:10),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color:Colors.black.withOpacity(0.05), blurRadius:8, offset:const Offset(0,3))],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(8,4,14,4),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: urls.isNotEmpty
                          ? Image.network(AppConfig.imageUrl(urls[0] as String),
                              width:56, height:56, fit:BoxFit.cover,
                              errorBuilder:(_,__,___)=>Container(width:56,height:56,
                                color:const Color(0xFFF0EDE8),
                                child:Center(child:Text(p['emoji']??'📦', style:const TextStyle(fontSize:24)))))
                          : Container(width:56, height:56, color:const Color(0xFFF0EDE8),
                              child:Center(child:Text(p['emoji']??'📦', style:const TextStyle(fontSize:24)))),
                    ),
                    title: Text(p['name']??'', textAlign:TextAlign.right, style:AppText.heading3.copyWith(fontSize:14)),
                    subtitle: Text('${p['price']} د.ك', textAlign:TextAlign.right, style:AppText.price.copyWith(fontSize:13)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color:Colors.red),
                      onPressed: ()=>_delete(p['id'] as int),
                    ),
                  ),
                );
              },
            ),
          ),
    floatingActionButton: FloatingActionButton.extended(
      backgroundColor: AppTheme.primary,
      icon: const Icon(Icons.add, color:Colors.white),
      label: const Text('إضافة منتج', style:TextStyle(fontFamily:'Tajawal', fontWeight:FontWeight.w700, color:Colors.white)),
      onPressed: () async {
        final added = await Navigator.push<bool>(context,
            MaterialPageRoute(builder:(_)=>const _AddProductScreen()));
        if (added==true) _load();
      },
    ),
  );
}

// ─── شاشة إضافة منتج ─────────────────────────────────────────────────────
class _AddProductScreen extends StatefulWidget {
  const _AddProductScreen();
  @override State<_AddProductScreen> createState() => _AddProductScreenState();
}
class _AddProductScreenState extends State<_AddProductScreen> {
  final _name  = TextEditingController();
  final _price = TextEditingController();
  final _desc  = TextEditingController();
  final _stock = TextEditingController(text:'1');
  String _emoji = '📿';
  String? _categoryId;
  List<XFile> _images = [];
  bool _loading = false;
  String? _error;
  List<dynamic> _categories = [];

  static const _emojis = ['📿','💎','💍','🏺','🪬','🔮','🌙','⭐','🌟','🪩'];

  @override void initState() { super.initState(); _loadCats(); }

  Future<void> _loadCats() async {
    try {
      final r = await APIService.instance.adminCategories();
      setState(() => _categories = r['data'] ?? []);
    } catch (_) {}
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality:80);
    if (picked.isNotEmpty) setState(() => _images = picked.take(6).toList());
  }

  Future<void> _submit() async {
    if (_name.text.isEmpty || _price.text.isEmpty) {
      setState(() => _error = 'أدخل الاسم والسعر'); return;
    }
    if (_categoryId == null) {
      setState(() => _error = 'اختر التصنيف أولاً'); return;
    }
    setState(() { _loading=true; _error=null; });
    try {
      // رفع الصور (اختياري — لو فشل نكمل بدون صور)
      List<String> urls = [];
      if (_images.isNotEmpty) {
        try {
          urls = await APIService.instance.uploadImages(_images);
        } catch (_) {
          // تجاهل خطأ رفع الصور وأكمل الإضافة
        }
      }
      await APIService.instance.adminAddProduct({
        'name': _name.text,
        'price': double.tryParse(_price.text) ?? 0,
        'description': _desc.text,
        'emoji': _emoji,
        'stock': int.tryParse(_stock.text) ?? 1,
        'category_id': int.parse(_categoryId!),
        'image_urls': urls,
      });
      if (mounted) Navigator.pop(context, true);
    } catch(e) { setState(() { _error = e.toString(); _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title:const Text('إضافة منتج جديد')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment:CrossAxisAlignment.end, children:[
        // إيموجي
        const Text('الإيموجي', style:TextStyle(fontFamily:'Tajawal', fontWeight:FontWeight.w700, fontSize:14)),
        const SizedBox(height:8),
        SizedBox(height:50, child:ListView(scrollDirection:Axis.horizontal, children:_emojis.map((e)=>
          GestureDetector(
            onTap:()=>setState(()=>_emoji=e),
            child:AnimatedContainer(duration:const Duration(milliseconds:200),
              margin:const EdgeInsets.only(left:8), width:44, height:44,
              decoration:BoxDecoration(
                color:_emoji==e?AppTheme.primary:Colors.grey.shade100,
                borderRadius:BorderRadius.circular(12)),
              child:Center(child:Text(e,style:const TextStyle(fontSize:22)))),
          )).toList())),
        const SizedBox(height:16),
        Q8Field(hint:'اسم المنتج', controller:_name, icon:Icons.label),
        const SizedBox(height:12),
        TextField(
          controller: _price,
          keyboardType: const TextInputType.numberWithOptions(decimal:true),
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily:'Tajawal', fontSize:14),
          decoration: InputDecoration(
            hintText: 'السعر',
            hintTextDirection: TextDirection.rtl,
            filled: true, fillColor: const Color(0xFFF0F0EB),
            border: OutlineInputBorder(borderRadius:BorderRadius.circular(14), borderSide:BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal:16, vertical:15),
            prefixIcon: const Icon(Icons.payments_outlined, color:AppTheme.primary, size:20),
            suffixText: 'د.ك',
            suffixStyle: const TextStyle(fontFamily:'Tajawal', fontWeight:FontWeight.w700, color:AppTheme.primary, fontSize:14),
          ),
        ),
        const SizedBox(height:12),
        Q8Field(hint:'الكمية المتاحة', controller:_stock, icon:Icons.inventory, keyboard:TextInputType.number),
        const SizedBox(height:12),
        if (_categories.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            value: _categoryId,
            decoration: InputDecoration(filled:true, fillColor:const Color(0xFFF0F0EB),
              border:OutlineInputBorder(borderRadius:BorderRadius.circular(14), borderSide:BorderSide.none),
              contentPadding:const EdgeInsets.symmetric(horizontal:16, vertical:15)),
            hint: const Text('اختر التصنيف', style:TextStyle(fontFamily:'Tajawal', fontSize:14)),
            items: _categories.map<DropdownMenuItem<String>>((c)=>DropdownMenuItem(
              value:c['id'].toString(),
              child:Text(c['name'] ?? '', style:const TextStyle(fontFamily:'Tajawal', fontSize:14)),
            )).toList(),
            onChanged:(v)=>setState(()=>_categoryId=v),
          ),
          const SizedBox(height:12),
        ],
        TextField(controller:_desc, textAlign:TextAlign.right, maxLines:3,
          style:const TextStyle(fontFamily:'Tajawal', fontSize:14),
          decoration:InputDecoration(hintText:'وصف المنتج...', hintTextDirection:TextDirection.rtl,
            filled:true, fillColor:const Color(0xFFF0F0EB),
            border:OutlineInputBorder(borderRadius:BorderRadius.circular(14), borderSide:BorderSide.none),
            contentPadding:const EdgeInsets.all(16),
            prefixIcon:const Icon(Icons.description, color:AppTheme.primary, size:20))),
        const SizedBox(height:16),
        GestureDetector(
          onTap: _pickImages,
          child:Container(width:double.infinity, padding:const EdgeInsets.symmetric(vertical:16),
            decoration:BoxDecoration(color:AppTheme.primary.withOpacity(0.05),
              borderRadius:BorderRadius.circular(14),
              border:Border.all(color:AppTheme.primary.withOpacity(0.3))),
            child:Column(children:[
              const Icon(Icons.add_photo_alternate_outlined, color:AppTheme.primary, size:32),
              const SizedBox(height:6),
              Text(_images.isEmpty?'اضغط لإضافة صور (حتى 6)':'${_images.length} صورة محددة',
                style:const TextStyle(fontFamily:'Tajawal', fontWeight:FontWeight.w600, fontSize:14, color:AppTheme.primary)),
            ])),
        ),
        if (_images.isNotEmpty) ...[
          const SizedBox(height:10),
          SizedBox(height:80, child:ListView.builder(
            scrollDirection:Axis.horizontal, itemCount:_images.length,
            itemBuilder:(_, i)=>Stack(children:[
              Container(width:80, height:80, margin:const EdgeInsets.only(left:8),
                child:ClipRRect(borderRadius:BorderRadius.circular(10),
                  child:Image.file(File(_images[i].path), fit:BoxFit.cover))),
              Positioned(top:2, right:2,
                child:GestureDetector(
                  onTap:()=>setState(()=>_images.removeAt(i)),
                  child:Container(padding:const EdgeInsets.all(2),
                    decoration:const BoxDecoration(color:Colors.red, shape:BoxShape.circle),
                    child:const Icon(Icons.close, size:12, color:Colors.white)))),
            ]))),
        ],
        if (_error!=null) ...[const SizedBox(height:10), ErrorBanner(_error!)],
        const SizedBox(height:20),
        Q8Button(label:'إضافة المنتج', isLoading:_loading, onTap:_submit),
        const SizedBox(height:30),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════
// TAB 3: المستخدمون
// ═══════════════════════════════════════════════
class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override State<_UsersTab> createState() => _UsersTabState();
}
class _UsersTabState extends State<_UsersTab> {
  List<dynamic> _users = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override void initState() { super.initState(); _load(); }

  Future<void> _load([String? q]) async {
    setState(() => _loading = true);
    try {
      final r = await APIService.instance.adminUsers(search:q);
      setState(() { _users = r['data'] ?? []; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _toggleBan(int id, bool isBanned) async {
    await APIService.instance.adminBanUser(id, !isBanned);
    _load(_search.text.isEmpty ? null : _search.text);
  }

  Future<void> _setRole(int id, String current) async {
    final role = await showDialog<String>(context:context, builder:(_)=>AlertDialog(
      title:const Text('تغيير الصلاحية', textAlign:TextAlign.right,
          style:TextStyle(fontFamily:'Tajawal', fontWeight:FontWeight.w700)),
      content:Column(mainAxisSize:MainAxisSize.min, children:['user','admin','moderator'].map((r)=>
        ListTile(
          title:Text(r, textAlign:TextAlign.right,
              style:TextStyle(fontFamily:'Tajawal', fontWeight:r==current?FontWeight.w700:FontWeight.normal)),
          trailing:r==current?const Icon(Icons.check, color:AppTheme.primary):null,
          onTap:()=>Navigator.pop(context, r),
        )).toList()),
    ));
    if (role!=null && role!=current) {
      await APIService.instance.adminSetRole(id, role);
      _load(_search.text.isEmpty ? null : _search.text);
    }
  }

  @override
  Widget build(BuildContext context) => Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(12,12,12,6),
      child:TextField(controller:_search, textAlign:TextAlign.right,
        style:const TextStyle(fontFamily:'Tajawal', fontSize:14),
        decoration:InputDecoration(hintText:'ابحث باسم أو رقم...',
          suffixIcon:IconButton(icon:const Icon(Icons.search), onPressed:()=>_load(_search.text)),
          filled:true, fillColor:Colors.white,
          border:OutlineInputBorder(borderRadius:BorderRadius.circular(12), borderSide:BorderSide.none),
          contentPadding:const EdgeInsets.symmetric(horizontal:14, vertical:12)),
        onSubmitted:_load)),
    Expanded(child:_loading ? const LoadingBody()
      : _users.isEmpty ? const EmptyState(emoji:'👥', message:'لا يوجد مستخدمون')
      : RefreshIndicator(
          onRefresh:()=>_load(),
          child:ListView.builder(
            padding:const EdgeInsets.fromLTRB(12,4,12,80),
            itemCount:_users.length,
            itemBuilder:(_, i) {
              final u = _users[i] as Map<String,dynamic>;
              final isBanned = u['is_banned']==true || u['is_banned']==1;
              final role = (u['role'] as String?) ?? 'user';
              return Container(
                margin:const EdgeInsets.only(bottom:8),
                decoration:BoxDecoration(
                  color:isBanned?Colors.red.shade50:Colors.white,
                  borderRadius:BorderRadius.circular(14),
                  border:isBanned?Border.all(color:Colors.red.shade100):null,
                  boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.04), blurRadius:6, offset:const Offset(0,2))],
                ),
                child:ListTile(
                  contentPadding:const EdgeInsets.fromLTRB(8,4,14,4),
                  leading:CircleAvatar(
                    backgroundColor:role=='admin'?AppTheme.gold.withOpacity(0.15):AppTheme.primary.withOpacity(0.1),
                    child:Text(((u['name'] as String?) ?? '؟')[0].toUpperCase(),
                      style:TextStyle(fontFamily:'Tajawal', fontWeight:FontWeight.w700,
                          color:role=='admin'?AppTheme.gold:AppTheme.primary))),
                  title:Text(u['name']??'', textAlign:TextAlign.right, style:AppText.heading3.copyWith(fontSize:14)),
                  subtitle:Column(crossAxisAlignment:CrossAxisAlignment.end, children:[
                    Text(u['phone']??'', style:AppText.caption),
                    const SizedBox(height:3),
                    Wrap(spacing:4, children:[
                      Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:2),
                        decoration:BoxDecoration(color:role=='admin'?AppTheme.gold.withOpacity(0.1):Colors.grey.shade100,
                            borderRadius:BorderRadius.circular(8)),
                        child:Text(role, style:TextStyle(fontFamily:'Tajawal', fontSize:11,
                            color:role=='admin'?AppTheme.gold:AppTheme.textLight))),
                      if (isBanned) Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:2),
                        decoration:BoxDecoration(color:Colors.red.shade100, borderRadius:BorderRadius.circular(8)),
                        child:const Text('محظور', style:TextStyle(fontFamily:'Tajawal', fontSize:11, color:Colors.red))),
                    ]),
                  ]),
                  trailing:PopupMenuButton<String>(
                    icon:const Icon(Icons.more_vert, color:AppTheme.textLight),
                    onSelected:(v){
                      if(v=='ban') _toggleBan(u['id'], isBanned);
                      if(v=='role') _setRole(u['id'], role);
                    },
                    itemBuilder:(_)=>[
                      PopupMenuItem(value:'ban', child:Row(mainAxisAlignment:MainAxisAlignment.end, children:[
                        Text(isBanned?'رفع الحظر':'حظر', style:TextStyle(fontFamily:'Tajawal', color:isBanned?Colors.green:Colors.red)),
                        const SizedBox(width:8),
                        Icon(isBanned?Icons.lock_open:Icons.block, color:isBanned?Colors.green:Colors.red, size:18),
                      ])),
                      const PopupMenuItem(value:'role', child:Row(mainAxisAlignment:MainAxisAlignment.end, children:[
                        Text('تغيير الصلاحية', style:TextStyle(fontFamily:'Tajawal')),
                        SizedBox(width:8),
                        Icon(Icons.admin_panel_settings, size:18, color:AppTheme.primary),
                      ])),
                    ],
                  ),
                ),
              );
            }))),
  ]);
}

// ═══════════════════════════════════════════════
// TAB 4: المزادات
// ═══════════════════════════════════════════════
class _AuctionsTab extends StatefulWidget {
  const _AuctionsTab();
  @override State<_AuctionsTab> createState() => _AuctionsTabState();
}
class _AuctionsTabState extends State<_AuctionsTab> {
  List<dynamic> _auctions = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await APIService.instance.adminAuctions();
      setState(() { _auctions = r['data'] ?? []; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => _loading ? const LoadingBody()
      : _auctions.isEmpty ? const EmptyState(emoji:'🔨', message:'لا توجد مزادات')
      : RefreshIndicator(
          onRefresh:_load,
          child:ListView.builder(
            padding:const EdgeInsets.fromLTRB(12,12,12,80),
            itemCount:_auctions.length,
            itemBuilder:(_, i) {
              final a = _auctions[i];
              final isActive = a['status']=='active';
              return Container(
                margin:const EdgeInsets.only(bottom:10),
                decoration:BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(14),
                  boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05), blurRadius:8, offset:const Offset(0,3))]),
                child:ListTile(
                  contentPadding:const EdgeInsets.fromLTRB(8,6,14,6),
                  leading:Container(padding:const EdgeInsets.all(8),
                    decoration:BoxDecoration(
                      color:isActive?Colors.green.shade50:Colors.grey.shade100,
                      borderRadius:BorderRadius.circular(10)),
                    child:Icon(Icons.gavel, color:isActive?Colors.green:Colors.grey, size:22)),
                  title:Text(a['title']??'', textAlign:TextAlign.right,
                      style:AppText.heading3.copyWith(fontSize:14), maxLines:2),
                  subtitle:Text('${a['current_price']} د.ك | ${a['bids_count']??0} مزايدة',
                      textAlign:TextAlign.right, style:AppText.caption),
                  trailing:isActive ? IconButton(
                    icon:const Icon(Icons.stop_circle_outlined, color:Colors.red),
                    tooltip:'إنهاء المزاد',
                    onPressed:() async {
                      await APIService.instance.adminEndAuction(a['id'] as int);
                      _load();
                    }) : null,
                ),
              );
            }));
}
