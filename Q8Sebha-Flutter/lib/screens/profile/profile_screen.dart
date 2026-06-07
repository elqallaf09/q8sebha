import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../main.dart';
import '../../widgets/common_widgets.dart';
import '../admin/admin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Order> _orders = [];
  bool _ordersLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  Future<void> _loadOrders() async {
    final auth = context.read<AuthProvider>();
    if (auth.isGuest || auth.currentUser == null) return;
    setState(() => _ordersLoading = true);
    try { _orders = await APIService.instance.myOrders(); } catch (_) {}
    if (mounted) setState(() => _ordersLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isGuest) return _guestView(context);
    final u = auth.currentUser;
    if (u == null) return const Scaffold(body: LoadingBody());
    return _userView(context, u, auth);
  }

  Widget _guestView(BuildContext ctx) => Scaffold(
    backgroundColor: AppTheme.bg,
    body: CustomScrollView(slivers: [
      SliverAppBar(
        pinned: true,
        backgroundColor: AppTheme.primary,
        title: const Text('حسابي',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, color: Colors.white)),
        centerTitle: true,
      ),
      SliverFillRemaining(
        child: Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF2D2D50)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppTheme.gold.withOpacity(0.2), blurRadius: 20)],
              ),
              child: const Center(child: Text('👤', style: TextStyle(fontSize: 50))),
            ),
            const SizedBox(height: 24),
            const Text('أنت تتصفح كضيف',
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 22)),
            const SizedBox(height: 8),
            const Text('سجّل دخولك للاستمتاع بجميع الميزات',
              style: TextStyle(fontFamily: 'Tajawal', color: AppTheme.textMid, fontSize: 15),
              textAlign: TextAlign.center),
            const SizedBox(height: 32),
            Q8Button(
              label: 'تسجيل الدخول / إنشاء حساب',
              onTap: () => ctx.read<AuthProvider>().appState = AppState.auth,
            ),
          ]),
        )),
      ),
    ]),
  );

  Widget _userView(BuildContext ctx, User u, AuthProvider auth) => Scaffold(
    backgroundColor: AppTheme.bg,
    body: CustomScrollView(slivers: [
      // ─── Header ───────────────────────────────────────────────────────
      SliverAppBar(
        expandedHeight: 180,
        pinned: true,
        backgroundColor: AppTheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () => _showEditSheet(ctx),
          ),
        ],
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
              Positioned(top: -30, right: -30,
                child: Container(width: 150, height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.gold.withOpacity(0.05),
                  ))),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(u.name,
                              style: const TextStyle(fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w800, fontSize: 22, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(u.phone,
                              style: TextStyle(fontFamily: 'Tajawal', fontSize: 14,
                                color: Colors.white.withOpacity(0.7))),
                            if (u.role != 'user') ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.goldLight, AppTheme.gold]),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(u.role == 'admin' ? '⚙️ أدمن' : '🏪 بائع',
                                  style: const TextStyle(fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white)),
                              ),
                            ],
                          ]),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.gold.withOpacity(0.6), width: 2),
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: const Center(child: Text('📿', style: TextStyle(fontSize: 30))),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),

      // ─── المحتوى ──────────────────────────────────────────────────────
      SliverToBoxAdapter(
        child: Column(children: [
          const SizedBox(height: 16),

          // معلومات الحساب
          _sectionCard('معلومات الحساب', [
            _infoTile(Icons.phone, 'رقم الهاتف', u.phone),
            _infoTile(Icons.email_outlined, 'البريد', u.email ?? '—'),
            _infoTile(Icons.chat_bubble_outline, 'طريقة التواصل', u.contactMethod ?? '—'),
            _infoTile(Icons.local_shipping_outlined, 'التوصيل', u.deliveryMethod ?? '—'),
            if (u.deliveryArea != null) _infoTile(Icons.location_on_outlined, 'المنطقة', u.deliveryArea!),
          ]),

          const SizedBox(height: 12),

          // الطلبات
          _sectionCard('طلباتي', [
            if (_ordersLoading)
              const Padding(padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(color: AppTheme.primary))),
            if (!_ordersLoading && _orders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(children: [
                  const Text('🛒', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text('لا توجد طلبات بعد',
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, color: AppTheme.textLight)),
                ]),
              ),
            ..._orders.take(5).map((o) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(o.productEmoji ?? '📿',
                  style: const TextStyle(fontSize: 22))),
              ),
              title: Text(o.productName ?? 'منتج',
                textAlign: TextAlign.right,
                style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('${o.orderNumber} — ${o.statusDisplay}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: AppTheme.textMid)),
              trailing: Text(o.totalFormatted,
                style: const TextStyle(fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 14)),
            )),
          ]),

          const SizedBox(height: 12),

          // لوحة الأدمن
          if (u.role == 'admin' || u.role == 'moderator')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminScreen())),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF2D2D50)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.arrow_back_ios_new, color: Colors.white38, size: 16),
                      Row(children: [
                        const Text('لوحة الإدارة',
                          style: TextStyle(fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // تسجيل الخروج
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => _confirmLogout(ctx, auth),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade100),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.arrow_back_ios_new, color: Colors.red, size: 16),
                    const Row(children: [
                      Text('تسجيل الخروج',
                        style: TextStyle(fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700, fontSize: 15, color: Colors.red)),
                      SizedBox(width: 10),
                      Icon(Icons.logout, color: Colors.red, size: 20),
                    ]),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 100),
        ]),
      ),
    ]),
  );

  Widget _sectionCard(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(title,
            style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
              fontSize: 14, color: AppTheme.textMid)),
        ),
        const Divider(height: 1),
        ...children,
      ]),
    ),
  );

  Widget _infoTile(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(value,
          style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w600,
            fontSize: 14, color: AppTheme.textDark)),
        Row(children: [
          Text(label,
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: AppTheme.textLight)),
          const SizedBox(width: 8),
          Icon(icon, color: AppTheme.primary, size: 18),
        ]),
      ],
    ),
  );

  void _showEditSheet(BuildContext ctx) => showModalBottomSheet(
    context: ctx, isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _EditProfileSheet(),
  );

  void _confirmLogout(BuildContext ctx, AuthProvider auth) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      title: const Text('تسجيل الخروج', textAlign: TextAlign.right,
        style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700)),
      content: const Text('هل تريد تسجيل الخروج؟', textAlign: TextAlign.right,
        style: TextStyle(fontFamily: 'Tajawal')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () { Navigator.pop(ctx); auth.logout(); },
          child: const Text('خروج')),
      ],
    ),
  );
}

// ─── تعديل الملف الشخصي ─────────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();
  @override State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  String _contact  = 'whatsapp';
  String _delivery = 'delivery';
  final _area    = TextEditingController();
  final _address = TextEditingController();
  bool _loading  = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().currentUser;
    _contact  = u?.contactMethod  ?? 'whatsapp';
    _delivery = u?.deliveryMethod ?? 'delivery';
    _area.text    = u?.deliveryArea    ?? '';
    _address.text = u?.deliveryAddress ?? '';
  }

  @override
  Widget build(BuildContext ctx) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
      left: 20, right: 20, top: 20,
    ),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
      // handle
      Center(child: Container(width: 40, height: 4,
        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 16),
      const Text('تعديل الملف الشخصي',
        style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 18)),
      const SizedBox(height: 20),

      const Text('طريقة التواصل',
        style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: AppTheme.textMid)),
      const SizedBox(height: 8),
      ToggleButtons(
        isSelected: [_contact == 'whatsapp', _contact == 'phone', _contact == 'both'],
        onPressed: (i) => setState(() => _contact = ['whatsapp', 'phone', 'both'][i]),
        borderRadius: BorderRadius.circular(12),
        selectedColor: Colors.white, fillColor: AppTheme.primary,
        children: const [
          Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Text('واتساب', style: TextStyle(fontFamily: 'Tajawal'))),
          Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Text('اتصال', style: TextStyle(fontFamily: 'Tajawal'))),
          Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Text('الاثنان', style: TextStyle(fontFamily: 'Tajawal'))),
        ],
      ),
      const SizedBox(height: 16),

      const Text('طريقة التوصيل',
        style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: AppTheme.textMid)),
      const SizedBox(height: 8),
      ToggleButtons(
        isSelected: [_delivery == 'delivery', _delivery == 'pickup'],
        onPressed: (i) => setState(() => _delivery = ['delivery', 'pickup'][i]),
        borderRadius: BorderRadius.circular(12),
        selectedColor: Colors.white, fillColor: AppTheme.primary,
        children: const [
          Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: Text('توصيل', style: TextStyle(fontFamily: 'Tajawal'))),
          Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: Text('استلام', style: TextStyle(fontFamily: 'Tajawal'))),
        ],
      ),
      const SizedBox(height: 16),
      Q8Field(hint: 'المنطقة', controller: _area, icon: Icons.location_on),
      const SizedBox(height: 10),
      Q8Field(hint: 'العنوان', controller: _address, icon: Icons.home),
      const SizedBox(height: 20),
      Q8Button(label: 'حفظ التغييرات', isLoading: _loading, onTap: _save),
    ]),
  );

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await APIService.instance.updateProfile({
        'contact_method': _contact, 'delivery_method': _delivery,
        'delivery_area': _area.text, 'delivery_address': _address.text,
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }
}
