import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../main.dart';
import '../../widgets/common_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<NotificationProvider>().fetchAll());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationProvider>();
    return Scaffold(
      appBar:AppBar(
        title:const Text('الإشعارات 🔔'),
        actions:[
          if (vm.notifications.any((n)=>!n.isRead))
            TextButton(
              onPressed:()=>vm.markAllRead(),
              child:const Text('قراءة الكل',style:TextStyle(color:Colors.white,fontFamily:'Tajawal',fontSize:13))),
        ],
      ),
      body:vm.isLoading
        ? const LoadingBody()
        : vm.notifications.isEmpty
          ? const EmptyState(emoji:'🔔', message:'لا توجد إشعارات')
          : RefreshIndicator(
              onRefresh:()=>vm.fetchAll(),
              child:ListView.builder(
                itemCount:vm.notifications.length,
                itemBuilder:(_,i){
                  final n = vm.notifications[i];
                  return Dismissible(
                    key:Key('n${n.id}'),
                    background:Container(color:AppTheme.primary,
                      alignment:Alignment.centerRight,
                      padding:const EdgeInsets.only(right:20),
                      child:const Icon(Icons.done_all,color:Colors.white)),
                    direction:DismissDirection.endToStart,
                    onDismissed:(_)=>vm.markRead(n.id),
                    child:ListTile(
                      tileColor:n.isRead?null:AppTheme.primary.withOpacity(0.05),
                      leading:Text(n.icon,style:const TextStyle(fontSize:26)),
                      title:Text(n.title,
                        style:TextStyle(fontFamily:'Tajawal',fontWeight:n.isRead?FontWeight.w500:FontWeight.w700,fontSize:14),
                        textAlign:TextAlign.right),
                      subtitle:Text(n.body,
                        style:const TextStyle(fontFamily:'Tajawal',fontSize:12,color:Colors.grey),
                        maxLines:2,textAlign:TextAlign.right),
                      trailing:n.isRead?null:Container(
                        width:10,height:10,
                        decoration:const BoxDecoration(color:AppTheme.primary,shape:BoxShape.circle)),
                      onTap:()=>vm.markRead(n.id),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
