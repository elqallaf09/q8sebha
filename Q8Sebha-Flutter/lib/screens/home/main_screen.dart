import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../main.dart';
import '../products/products_screen.dart';
import '../auctions/auction_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../favorites/favorites_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  final _screens = const [
    ProductsScreen(),
    AuctionListScreen(),
    FavoritesScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: _BottomNav(
        selected: _tab,
        unread: unread,
        onTap: (i) {
          setState(() => _tab = i);
          if (i == 3) context.read<NotificationProvider>().fetchAll();
        },
      ),
    );
  }
}

// ─── شريط التنقل الفاخر ──────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selected;
  final int unread;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selected, required this.unread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4)),
        ],
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag_rounded,
                  label: 'المنتجات', index: 0, selected: selected, onTap: onTap),
              _NavItem(icon: Icons.gavel_outlined, activeIcon: Icons.gavel_rounded,
                  label: 'المزادات', index: 1, selected: selected, onTap: onTap),
              _NavItem(icon: Icons.favorite_outline_rounded, activeIcon: Icons.favorite_rounded,
                  label: 'المفضلة', index: 2, selected: selected, onTap: onTap),
              _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded,
                  label: 'الإشعارات', index: 3, selected: selected, onTap: onTap, badge: unread),
              _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,
                  label: 'حسابي', index: 4, selected: selected, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, selected;
  final ValueChanged<int> onTap;
  final int badge;
  const _NavItem({
    required this.icon, required this.activeIcon, required this.label,
    required this.index, required this.selected, required this.onTap, this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == selected;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primary : AppTheme.textLight,
              size: 24),
            if (badge > 0) Positioned(
              top: -4, left: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text('${badge > 9 ? '9+' : badge}',
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
              color: isActive ? AppTheme.primary : AppTheme.textLight,
            ),
            child: Text(label),
          ),
        ]),
      ),
    );
  }
}

// ─── SliverAppBar مشترك ───────────────────────────────────────────────────
class Q8SliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? bottom;
  const Q8SliverAppBar({super.key, required this.title, this.actions, this.bottom});

  @override
  Widget build(BuildContext context) => SliverAppBar(
    floating: true,
    snap: true,
    backgroundColor: AppTheme.primary,
    foregroundColor: Colors.white,
    title: Text(title, style: const TextStyle(
      fontFamily: 'Tajawal', fontWeight: FontWeight.w700,
      fontSize: 18, color: Colors.white,
    )),
    centerTitle: true,
    actions: actions,
    bottom: bottom != null ? PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: bottom!,
    ) : null,
    elevation: 0,
  );
}
