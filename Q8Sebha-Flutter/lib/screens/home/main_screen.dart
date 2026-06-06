import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
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
      body: IndexedStack(index:_tab, children:_screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) { setState(()=>_tab=i); if(i==2) context.read<NotificationProvider>().fetchAll(); },
        items: [
          const BottomNavigationBarItem(icon:Icon(Icons.shopping_bag), label:'المنتجات'),
          const BottomNavigationBarItem(icon:Icon(Icons.gavel), label:'المزاد'),
          BottomNavigationBarItem(
            icon: Stack(children:[
              const Icon(Icons.notifications),
              if (unread > 0) Positioned(right:0,top:0,
                child:Container(
                  padding:const EdgeInsets.all(2),
                  decoration:const BoxDecoration(color:Colors.red, shape:BoxShape.circle),
                  child:Text('${unread>99?99:unread}', style:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.bold)),
                )),
            ]),
            label:'الإشعارات',
          ),
          const BottomNavigationBarItem(icon:Icon(Icons.person), label:'حسابي'),
        ],
      ),
    );
  }
}
