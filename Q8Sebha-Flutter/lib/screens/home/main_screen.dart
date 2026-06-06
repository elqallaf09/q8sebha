import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../main.dart';
import '../products/products_screen.dart';
import '../auctions/auction_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  final _screens = const [
    ProductsScreen(),
    AuctionListScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -2))],
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) {
            setState(() => _tab = i);
            if (i == 2) context.read<NotificationProvider>().fetchAll();
          },
          height: 66,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag),
              label: 'المنتجات',
            ),
            const NavigationDestination(
              icon: Icon(Icons.gavel_outlined),
              selectedIcon: Icon(Icons.gavel),
              label: 'المزادات',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('${unread > 99 ? 99 : unread}',
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 10)),
                child: const Icon(Icons.notifications_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: unread > 0,
                label: Text('${unread > 99 ? 99 : unread}',
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 10)),
                child: const Icon(Icons.notifications),
              ),
              label: 'الإشعارات',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
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
