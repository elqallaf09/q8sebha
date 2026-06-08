import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../main.dart';
import '../../widgets/common_widgets.dart';
import '../admin/admin_screen.dart';
import '../orders/orders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  List<Order> _orders = [];
  bool _ordersLoading = false;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
      _anim.forward();
    });
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

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

  // ─── Guest View ─────────────────────────────────────────────────────────────
  Widget _guestView(BuildContext ctx) => Scaffold(
    backgroundColor: const Color(0xFFF4F3F0),
    body: CustomScrollView(slivers: [
      SliverAppBar(
        pinned: true, expandedHeight: 200,
        backgroundColor: const Color(0xFF1A1A2E),
        flexibleSpace: FlexibleSpaceBar(
          background: _headerBg(),
        ),
      ),
      SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF2D2D50)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                    color: AppTheme.gold.withOpacity(0.25), blurRadius: 24)],
                ),
                child: const Center(
                  child: Text('👤', style: TextStyle(fontSize: 44))),
              ),
              const SizedBox(height: 24),
              const Text('أنت تتصفح كضيف',
                style: TextStyle(fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w800, fontSize: 22,
                    color: AppTheme.textDark)),
              const SizedBox(height: 8),
              const Text('سجّل دخولك للاستمتاع بجميع الميزات',
                style: TextStyle(fontFamily: 'Tajawal',
                    color: AppTheme.textMid, fontSize: 15),
                textAlign: TextAlign.center),
              const SizedBox(height: 32),
              Q8Button(
                label: 'تسجيل الدخول / إنشاء حساب',
                onTap: () => ctx.read<AuthProvider>().appState = AppState.auth,
              ),
            ]),
          ),
        ),
      ),
    ]),
  );

  // ─── User View ──────────────────────────────────────────────────────────────
  Widget _userView(BuildContext ctx, User u, AuthProvider auth) => Scaffold(
    backgroundColor: const Color(0xFFF4F3F0),
    body: CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ─── SliverAppBar ─────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: const Color(0xFF1A1A2E),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () => _showEditSheet(ctx),
                child: Container(
                  width: 38, height: 38,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: _headerBg(user: u),
          ),
        ),

        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _anim,
            child: Column(children: [
              const SizedBox(height: 16),

              // ─── Stats ──────────────────────────────────────────────
              _statsRow(u),
              const SizedBox(height: 16),

              // ─── Account Info ────────────────────────────────────────
              _sectionCard(
                icon: Icons.person_outline_rounded,
                title: 'معلومات الحساب',
                children: [
                  _infoTile(Icons.phone_outlined, 'رقم الهاتف', u.phone),
                  if (u.email != null && u.email!.isNotEmpty)
                    _infoTile(Icons.email_outlined, 'البريد', u.email!),
                  _infoTile(
                    Icons.chat_bubble_outline_rounded,
                    'التواصل',
                    _contactLabel(u.contactMethod),
                  ),
                  _infoTile(
                    Icons.local_shipping_outlined,
                    'التوصيل',
                    _deliveryLabel(u.deliveryMethod),
                  ),
                  if (u.deliveryArea != null && u.deliveryArea!.isNotEmpty)
                    _infoTile(Icons.location_on_outlined, 'المنطقة', u.deliveryArea!),
                ],
              ),
              const SizedBox(height: 14),

              // ─── Orders ───────────────────────────────────────────────
              _sectionCard(
                icon: Icons.shopping_bag_outlined,
                title: 'طلباتي',
                trailing: _orders.isNotEmpty
                    ? Text('${_orders.length}',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppTheme.gold,
                        ))
                    : null,
                children: [
                  if (_ordersLoading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator(
                          color: AppTheme.primary, strokeWidth: 2)),
                    )
                  else if (_orders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EDE8),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('🛒', style: TextStyle(fontSize: 28))),
                        ),
                        const SizedBox(height: 12),
                        const Text('لا توجد طلبات بعد',
                          style: TextStyle(fontFamily: 'Tajawal',
                              fontSize: 14, color: AppTheme.textLight)),
                      ]),
                    )
                  else ...[
                    ..._orders.take(5).map((o) => _orderTile(o)),
                    if (_orders.length > 5 || true)
                      InkWell(
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const OrdersScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: const Center(
                            child: Text('عرض كل الطلبات →',
                              style: TextStyle(fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13, color: AppTheme.primary))))),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // ─── Admin Panel ─────────────────────────────────────────
              if (u.role == 'admin' || u.role == 'moderator') ...[
                _actionCard(
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminScreen())),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF2D2D55)]),
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'لوحة الإدارة',
                  subtitle: 'إدارة المنتجات والمزادات والمستخدمين',
                  iconBg: Colors.white.withOpacity(0.15),
                  textColor: Colors.white,
                  arrowColor: Colors.white38,
                ),
                const SizedBox(height: 10),
              ],

              // ─── Logout ──────────────────────────────────────────────
              _actionCard(
                onTap: () => _confirmLogout(ctx, auth),
                gradient: null,
                bgColor: Colors.white,
                border: Border.all(color: Colors.red.shade100),
                icon: Icons.logout_rounded,
                label: 'تسجيل الخروج',
                subtitle: 'الخروج من حسابك الحالي',
                iconBg: Colors.red.shade50,
                textColor: Colors.red.shade600,
                arrowColor: Colors.red.shade300,
                iconColor: Colors.red.shade400,
              ),

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    ),
  );

  // ─── Header Background ──────────────────────────────────────────────────────
  Widget _headerBg({User? user}) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0F0F1E), Color(0xFF1A1A2E), Color(0xFF252545)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Stack(children: [
      Positioned(top: -40, right: -40,
        child: Container(width: 200, height: 200,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: AppTheme.gold.withOpacity(0.06)))),
      Positioned(bottom: -30, left: -30,
        child: Container(width: 140, height: 140,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.03)))),
      if (user != null)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(children: [
                  // Avatar
                  Stack(children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2D2D50), Color(0xFF1A1A2E)]),
                        border: Border.all(color: AppTheme.gold.withOpacity(0.5), width: 2),
                      ),
                      child: const Center(
                        child: Text('📿', style: TextStyle(fontSize: 32))),
                    ),
                    if (user.isVerified == 1)
                      Positioned(
                        bottom: 2, left: 2,
                        child: Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50), shape: BoxShape.circle),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 12),
                        ),
                      ),
                  ]),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(user.name,
                          style: const TextStyle(fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w800, fontSize: 20,
                              color: Colors.white)),
                        const SizedBox(height: 3),
                        Text(user.phone,
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 13,
                              color: Colors.white.withOpacity(0.6))),
                        const SizedBox(height: 8),
                        if (user.role != 'user')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.goldLight, AppTheme.gold]),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(
                                color: AppTheme.gold.withOpacity(0.3),
                                blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Text(
                              user.role == 'admin' ? '⚙️ أدمن' : '🏪 بائع',
                              style: const TextStyle(fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w700, fontSize: 11,
                                color: Colors.white)),
                          ),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
    ]),
  );

  // ─── Stats Row ──────────────────────────────────────────────────────────────
  Widget _statsRow(User u) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(children: [
      _statCard('🛍️', '${u.totalPurchases}', 'مشتريات'),
      const SizedBox(width: 10),
      _statCard('🏆', '${u.totalWins}', 'فوز بمزاد'),
      const SizedBox(width: 10),
      _statCard('⭐', '${u.rating?.toStringAsFixed(1) ?? "5.0"}', 'التقييم'),
    ]),
  );

  Widget _statCard(String emoji, String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(
            fontFamily: 'Tajawal', fontWeight: FontWeight.w800,
            fontSize: 18, color: AppTheme.textDark)),
        Text(label, style: const TextStyle(
            fontFamily: 'Tajawal', fontSize: 11, color: AppTheme.textLight)),
      ]),
    ),
  );

  // ─── Section Card ───────────────────────────────────────────────────────────
  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (trailing != null) trailing
              else const SizedBox(),
              Row(children: [
                Text(title, style: const TextStyle(
                  fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                  fontSize: 15, color: AppTheme.textDark)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: AppTheme.primary),
                ),
              ]),
            ],
          ),
        ),
        Container(height: 1, color: const Color(0xFFF0EEE9)),
        ...children,
      ]),
    ),
  );

  // ─── Info Tile ──────────────────────────────────────────────────────────────
  Widget _infoTile(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // القيمة
        Expanded(
          child: Text(value,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontFamily: 'Tajawal', fontWeight: FontWeight.w600,
              fontSize: 14, color: AppTheme.textDark)),
        ),
        // التسمية + الأيقونة
        Row(children: [
          Text(label,
            style: const TextStyle(
                fontFamily: 'Tajawal', fontSize: 13,
                color: AppTheme.textLight)),
          const SizedBox(width: 8),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 16),
          ),
        ]),
      ],
    ),
  );

  // ─── Order Tile ─────────────────────────────────────────────────────────────
  Widget _orderTile(Order o) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: const Color(0xFFF0EEE9)),
      ),
    ),
    child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(o.totalFormatted,
          style: const TextStyle(fontFamily: 'Tajawal',
              fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 14)),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _orderStatusColor(o.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(o.statusDisplay,
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _orderStatusColor(o.status))),
        ),
      ]),
      const Spacer(),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(o.productName ?? 'منتج',
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Tajawal',
              fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 2),
        Text(o.orderNumber ?? '',
          style: const TextStyle(fontFamily: 'Tajawal',
              fontSize: 11, color: AppTheme.textLight)),
      ]),
      const SizedBox(width: 12),
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3EE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text(o.productEmoji ?? '📿',
            style: const TextStyle(fontSize: 20))),
      ),
    ]),
  );

  // ─── Action Card ────────────────────────────────────────────────────────────
  Widget _actionCard({
    required VoidCallback onTap,
    Gradient? gradient,
    Color? bgColor,
    BoxBorder? border,
    required IconData icon,
    Color? iconColor,
    required Color iconBg,
    required String label,
    required String subtitle,
    required Color textColor,
    required Color arrowColor,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: border,
          boxShadow: [BoxShadow(
            color: (gradient != null
                    ? const Color(0xFF1A1A2E)
                    : Colors.black)
                .withOpacity(0.07),
            blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Icon(Icons.arrow_back_ios_new_rounded, color: arrowColor, size: 14),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(label, style: TextStyle(
              fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
              fontSize: 15, color: textColor)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(
              fontFamily: 'Tajawal', fontSize: 11,
              color: textColor.withOpacity(0.6))),
          ]),
          const SizedBox(width: 12),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon,
                color: iconColor ?? textColor.withOpacity(0.8), size: 22),
          ),
        ]),
      ),
    ),
  );

  // ─── Helpers ────────────────────────────────────────────────────────────────
  String _contactLabel(String? v) {
    switch (v) {
      case 'whatsapp': return 'واتساب';
      case 'phone':    return 'اتصال';
      case 'both':     return 'واتساب + اتصال';
      default:         return v ?? '—';
    }
  }

  String _deliveryLabel(String? v) {
    switch (v) {
      case 'delivery': return 'توصيل للمنزل';
      case 'pickup':   return 'استلام مباشر';
      default:         return v ?? '—';
    }
  }

  Color _orderStatusColor(String? s) {
    switch (s) {
      case 'confirmed': return Colors.green;
      case 'pending':   return Colors.orange;
      case 'cancelled': return Colors.red;
      case 'delivered': return Colors.blue;
      default:          return AppTheme.textMid;
    }
  }

  void _showEditSheet(BuildContext ctx) => showModalBottomSheet(
    context: ctx, isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _EditProfileSheet(),
  );

  void _confirmLogout(BuildContext ctx, AuthProvider auth) => showModalBottomSheet(
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
          decoration: BoxDecoration(color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: Colors.red.shade50, shape: BoxShape.circle),
          child: Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 30),
        ),
        const SizedBox(height: 16),
        const Text('تسجيل الخروج',
          style: TextStyle(fontFamily: 'Tajawal',
              fontWeight: FontWeight.w800, fontSize: 20)),
        const SizedBox(height: 8),
        const Text('هل أنت متأكد من تسجيل الخروج؟',
          style: TextStyle(fontFamily: 'Tajawal',
              fontSize: 14, color: AppTheme.textMid),
          textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EEE8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('إلغاء', textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w700, color: AppTheme.textDark)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () { Navigator.pop(ctx); auth.logout(); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Text('خروج', textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 8),
      ]),
    ),
  );
}

// ─── Edit Profile Sheet ────────────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();
  @override State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  String _contact  = 'whatsapp';
  String _delivery = 'delivery';
  String _country  = 'الكويت';

  final _area      = TextEditingController();
  final _block     = TextEditingController();
  final _street    = TextEditingController();
  final _avenue    = TextEditingController();
  final _house     = TextEditingController();
  final _apartment = TextEditingController();

  bool _loading = false;

  static const _countries = [
    'الكويت', 'السعودية', 'الإمارات', 'قطر', 'البحرين', 'عُمان',
    'العراق', 'الأردن', 'مصر', 'لبنان', 'سوريا', 'اليمن',
    'المغرب', 'تونس', 'الجزائر', 'ليبيا',
  ];

  static const _kuwaitAreas = [
    'العاصمة', 'حولي', 'الفروانية', 'مبارك الكبير', 'الأحمدي', 'الجهراء',
    'السالمية', 'حولي', 'الرميثية', 'بيان', 'أبو حليفة', 'المنقف',
    'الجهراء', 'القصر', 'الصليبية', 'العارضية',
  ];

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().currentUser;
    _contact     = u?.contactMethod    ?? 'whatsapp';
    _delivery    = u?.deliveryMethod   ?? 'delivery';
    _country     = u?.deliveryCountry  ?? 'الكويت';
    _area.text   = u?.deliveryArea     ?? '';
    _block.text  = u?.deliveryBlock    ?? '';
    _street.text = u?.deliveryStreet   ?? '';
    _avenue.text = u?.deliveryAvenue   ?? '';
    _house.text  = u?.deliveryHouse    ?? '';
    _apartment.text = u?.deliveryApartment ?? '';
  }

  @override
  void dispose() {
    _area.dispose(); _block.dispose(); _street.dispose();
    _avenue.dispose(); _house.dispose(); _apartment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, sc) => Column(children: [
        // Handle + Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 22)),
              const Text('تعديل البيانات',
                style: TextStyle(fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w800, fontSize: 18)),
            ]),
            const SizedBox(height: 4),
            Divider(color: Colors.grey.shade100),
          ]),
        ),

        // المحتوى القابل للتمرير
        Expanded(
          child: ListView(
            controller: sc,
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 4,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            children: [
              // ── طريقة التواصل ─────────────────────────────────────────
              _label('طريقة التواصل'),
              const SizedBox(height: 8),
              Row(children: [
                _optionBtn('واتساب', Icons.message_outlined,
                    _contact == 'whatsapp', () => setState(() => _contact = 'whatsapp')),
                const SizedBox(width: 8),
                _optionBtn('اتصال', Icons.phone_outlined,
                    _contact == 'phone', () => setState(() => _contact = 'phone')),
                const SizedBox(width: 8),
                _optionBtn('الاثنان', Icons.more_horiz_rounded,
                    _contact == 'both', () => setState(() => _contact = 'both')),
              ]),
              const SizedBox(height: 16),

              // ── طريقة التوصيل ─────────────────────────────────────────
              _label('طريقة التوصيل'),
              const SizedBox(height: 8),
              Row(children: [
                _optionBtn('توصيل للمنزل', Icons.home_outlined,
                    _delivery == 'delivery', () => setState(() => _delivery = 'delivery')),
                const SizedBox(width: 8),
                _optionBtn('استلام مباشر', Icons.storefront_outlined,
                    _delivery == 'pickup', () => setState(() => _delivery = 'pickup')),
              ]),
              const SizedBox(height: 20),

              // ── العنوان ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEAE7E0)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Row(children: [
                    const Spacer(),
                    const Text('عنوان التوصيل', style: TextStyle(
                        fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
                        fontSize: 15, color: AppTheme.textDark)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.location_on_outlined,
                          size: 16, color: AppTheme.primary),
                    ),
                  ]),
                  const SizedBox(height: 14),

                  // الدولة
                  _label('الدولة'),
                  const SizedBox(height: 6),
                  _dropdownField(
                    value: _country,
                    items: _countries,
                    icon: Icons.flag_outlined,
                    onChanged: (v) => setState(() => _country = v!),
                  ),
                  const SizedBox(height: 12),

                  // المنطقة
                  _label('المنطقة'),
                  const SizedBox(height: 6),
                  _country == 'الكويت'
                    ? _dropdownField(
                        value: _kuwaitAreas.contains(_area.text) ? _area.text : null,
                        items: _kuwaitAreas,
                        icon: Icons.map_outlined,
                        hint: 'اختر المنطقة',
                        onChanged: (v) => setState(() => _area.text = v ?? ''),
                      )
                    : _field(_area, 'المنطقة', Icons.map_outlined),
                  const SizedBox(height: 12),

                  // قطعة + شارع
                  Row(children: [
                    Expanded(child: _field(_street, 'الشارع', Icons.turn_right_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_block, 'القطعة', Icons.grid_4x4_outlined)),
                  ]),
                  const SizedBox(height: 12),

                  // جادة + منزل
                  Row(children: [
                    Expanded(child: _field(_house, 'المنزل', Icons.home_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_avenue, 'الجادة', Icons.fork_right_outlined)),
                  ]),
                  const SizedBox(height: 12),

                  // شقة
                  _field(_apartment, 'رقم الشقة (اختياري)', Icons.apartment_outlined),
                ]),
              ),
              const SizedBox(height: 24),

              Q8Button(label: 'حفظ التغييرات', isLoading: _loading, onTap: _save),
            ],
          ),
        ),
      ]),
    ),
  );

  Widget _label(String text) => Text(text,
    textAlign: TextAlign.right,
    style: const TextStyle(fontFamily: 'Tajawal',
        fontSize: 13, color: AppTheme.textMid, fontWeight: FontWeight.w600));

  Widget _field(TextEditingController ctrl, String hint, IconData icon) =>
    TextField(
      controller: ctrl,
      textAlign: TextAlign.right,
      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Tajawal',
            fontSize: 13, color: AppTheme.textLight),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E4DC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E4DC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        prefixIcon: Icon(icon, size: 17, color: AppTheme.textLight),
      ),
    );

  Widget _dropdownField({
    required String? value,
    required List<String> items,
    required IconData icon,
    String? hint,
    required ValueChanged<String?> onChanged,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE8E4DC)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint ?? 'اختر', style: const TextStyle(
            fontFamily: 'Tajawal', fontSize: 13, color: AppTheme.textLight)),
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppTheme.textLight),
        style: const TextStyle(fontFamily: 'Tajawal',
            fontSize: 14, color: AppTheme.textDark),
        items: items.map((e) => DropdownMenuItem(
          value: e,
          child: Text(e, textAlign: TextAlign.right),
        )).toList(),
        onChanged: onChanged,
      ),
    ),
  );

  Widget _optionBtn(String label, IconData icon, bool selected, VoidCallback onTap) =>
    Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? const LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF2D2D50)]) : null,
            color: selected ? null : const Color(0xFFF5F3EE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.transparent : const Color(0xFFE8E4DC)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: selected ? Colors.white70 : AppTheme.textMid, size: 18),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
              fontFamily: 'Tajawal', fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              color: selected ? Colors.white : AppTheme.textMid)),
          ]),
        ),
      ),
    );

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await APIService.instance.updateProfile({
        'contact_method':      _contact,
        'delivery_method':     _delivery,
        'delivery_country':    _country,
        'delivery_area':       _area.text.trim(),
        'delivery_block':      _block.text.trim(),
        'delivery_street':     _street.text.trim(),
        'delivery_avenue':     _avenue.text.trim(),
        'delivery_house':      _house.text.trim(),
        'delivery_apartment':  _apartment.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التغييرات ✓',
              style: TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: Colors.green));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى',
            style: TextStyle(fontFamily: 'Tajawal')),
          backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _loading = false);
  }
}
