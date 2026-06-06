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
    setState(()=>_ordersLoading=true);
    try { _orders = await APIService.instance.myOrders(); } catch (_) {}
    if (mounted) setState(()=>_ordersLoading=false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isGuest) return _guestView(context);
    final u = auth.currentUser;
    if (u == null) return const Scaffold(body:LoadingBody());
    return _userView(context, u, auth);
  }

  Widget _guestView(BuildContext ctx) => Scaffold(
    appBar:AppBar(title:const Text('حسابي')),
    body:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      const Text('👤',style:TextStyle(fontSize:80)),
      const SizedBox(height:16),
      const Text('أنت تتصفح كضيف',style:TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:20)),
      const SizedBox(height:8),
      const Text('سجّل دخولك للاستمتاع بجميع الميزات',
        style:TextStyle(fontFamily:'Tajawal',color:Colors.grey,fontSize:15),textAlign:TextAlign.center),
      const SizedBox(height:24),
      Padding(padding:const EdgeInsets.symmetric(horizontal:40),
        child:Q8Button(label:'تسجيل الدخول / إنشاء حساب',
          onTap:()=>ctx.read<AuthProvider>().appState=AppState.auth)),
    ])),
  );

  Widget _userView(BuildContext ctx, User u, AuthProvider auth) => Scaffold(
    appBar:AppBar(title:const Text('حسابي'),
      actions:[IconButton(icon:const Icon(Icons.edit_outlined,color:Colors.white),
        onPressed:()=>_showEditSheet(ctx))]),
    body:ListView(children:[
      // رأس البروفايل
      Container(
        color:AppTheme.primary,
        padding:const EdgeInsets.fromLTRB(20,20,20,30),
        child:Row(children:[
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
            Text(u.name,style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:22,color:Colors.white)),
            const SizedBox(height:4),
            Text(u.phone,style:TextStyle(fontFamily:'Tajawal',fontSize:14,color:Colors.white.withOpacity(0.8))),
            if (u.role != 'user') ...[
              const SizedBox(height:8),
              Container(
                padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
                decoration:BoxDecoration(color:Colors.white24,borderRadius:BorderRadius.circular(10)),
                child:Text(u.role=='admin'?'⚙️ أدمن':'🏪 بائع',
                  style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:12,color:Colors.white)),
              ),
            ],
          ])),
          const SizedBox(width:16),
          CircleAvatar(radius:36, backgroundColor:Colors.white24,
            child:const Text('📿',style:TextStyle(fontSize:32))),
        ]),
      ),

      // معلومات
      _section('معلومات الحساب',[
        _info(Icons.phone,         'رقم الهاتف',     u.phone),
        _info(Icons.email_outlined,'البريد',          u.email ?? '—'),
        _info(Icons.chat_bubble_outline,'طريقة التواصل',u.contactMethod ?? '—'),
        _info(Icons.local_shipping_outlined,'التوصيل',u.deliveryMethod ?? '—'),
        if (u.deliveryArea!=null) _info(Icons.location_on_outlined,'المنطقة',u.deliveryArea!),
      ]),

      // الطلبات
      _section('طلباتي',[
        if (_ordersLoading) const Padding(padding:EdgeInsets.all(16),child:Center(child:CircularProgressIndicator())),
        if (!_ordersLoading && _orders.isEmpty)
          const Padding(padding:EdgeInsets.symmetric(vertical:12),
            child:Text('لا توجد طلبات بعد',textAlign:TextAlign.right,
              style:TextStyle(fontFamily:'Tajawal',color:Colors.grey))),
        ..._orders.take(5).map((o)=>ListTile(
          leading:Text(o.productEmoji??'📿',style:const TextStyle(fontSize:24)),
          title:Text(o.productName??'منتج',textAlign:TextAlign.right,
            style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w600,fontSize:14)),
          subtitle:Text('${o.orderNumber} — ${o.statusDisplay}',textAlign:TextAlign.right,
            style:const TextStyle(fontFamily:'Tajawal',fontSize:12)),
          trailing:Text(o.totalFormatted,
            style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,color:AppTheme.primary,fontSize:14)),
        )),
      ]),

      // لوحة الأدمن — مرئية دائماً (قيّدها لاحقاً)
      if (true || u.role == 'admin' || u.role == 'seller')
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
            icon: const Icon(Icons.admin_panel_settings_outlined, color: AppTheme.primary),
            label: const Text('لوحة الأدمن', style: TextStyle(fontFamily: 'Tajawal', color: AppTheme.primary, fontSize: 15)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primary),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

      // تسجيل الخروج
      Padding(padding:const EdgeInsets.all(20),
        child:OutlinedButton.icon(
          onPressed:()=>_confirmLogout(ctx, auth),
          icon:const Icon(Icons.logout,color:Colors.red),
          label:const Text('تسجيل الخروج',style:TextStyle(fontFamily:'Tajawal',color:Colors.red,fontSize:15)),
          style:OutlinedButton.styleFrom(
            side:const BorderSide(color:Colors.red),
            minimumSize:const Size(double.infinity,48),
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),
          ),
        )),
    ]),
  );

  Widget _section(String title, List<Widget> children) => Column(
    crossAxisAlignment:CrossAxisAlignment.end,
    children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,16,16,8),
        child:Text(title,style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:16,color:Colors.grey))),
      Container(color:Colors.white,child:Column(children:children)),
      const Divider(height:1),
    ],
  );

  Widget _info(IconData icon, String label, String value) => ListTile(
    leading:Icon(icon,color:AppTheme.primary,size:20),
    title:Text(label,style:const TextStyle(fontFamily:'Tajawal',fontSize:13,color:Colors.grey)),
    trailing:Text(value,style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w600,fontSize:14)),
  );

  void _showEditSheet(BuildContext ctx) => showModalBottomSheet(
    context:ctx, isScrollControlled:true,
    shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(20))),
    builder:(_)=>const _EditProfileSheet(),
  );

  void _confirmLogout(BuildContext ctx, AuthProvider auth) => showDialog(
    context:ctx,
    builder:(_)=>AlertDialog(
      title:const Text('تسجيل الخروج',textAlign:TextAlign.right,style:TextStyle(fontFamily:'Tajawal')),
      content:const Text('هل تريد تسجيل الخروج؟',textAlign:TextAlign.right,style:TextStyle(fontFamily:'Tajawal')),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء')),
        ElevatedButton(
          style:ElevatedButton.styleFrom(backgroundColor:Colors.red),
          onPressed:(){Navigator.pop(ctx); auth.logout();},
          child:const Text('خروج')),
      ],
    ),
  );
}

// ─── تعديل الملف الشخصي ─────────────────────────────────────────────────
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
  Widget build(BuildContext ctx) => Padding(
    padding:EdgeInsets.only(bottom:MediaQuery.of(ctx).viewInsets.bottom,left:20,right:20,top:20),
    child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.end,children:[
      const Text('تعديل الملف الشخصي',style:TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:18)),
      const SizedBox(height:16),
      const Text('طريقة التواصل',style:TextStyle(fontFamily:'Tajawal',fontSize:14)),
      ToggleButtons(
        isSelected:[_contact=='whatsapp',_contact=='phone',_contact=='both'],
        onPressed:(i){setState((){_contact=['whatsapp','phone','both'][i];});},
        borderRadius:BorderRadius.circular(10),
        selectedColor:Colors.white, fillColor:AppTheme.primary,
        children:const [Padding(padding:EdgeInsets.symmetric(horizontal:12),child:Text('واتساب',style:TextStyle(fontFamily:'Tajawal'))),
                        Padding(padding:EdgeInsets.symmetric(horizontal:12),child:Text('اتصال',style:TextStyle(fontFamily:'Tajawal'))),
                        Padding(padding:EdgeInsets.symmetric(horizontal:12),child:Text('الاثنان',style:TextStyle(fontFamily:'Tajawal')))],
      ),
      const SizedBox(height:12),
      const Text('طريقة التوصيل',style:TextStyle(fontFamily:'Tajawal',fontSize:14)),
      ToggleButtons(
        isSelected:[_delivery=='delivery',_delivery=='pickup'],
        onPressed:(i){setState((){_delivery=['delivery','pickup'][i];});},
        borderRadius:BorderRadius.circular(10),
        selectedColor:Colors.white, fillColor:AppTheme.primary,
        children:const [Padding(padding:EdgeInsets.symmetric(horizontal:16),child:Text('توصيل',style:TextStyle(fontFamily:'Tajawal'))),
                        Padding(padding:EdgeInsets.symmetric(horizontal:16),child:Text('استلام',style:TextStyle(fontFamily:'Tajawal')))],
      ),
      const SizedBox(height:12),
      Q8Field(hint:'المنطقة', controller:_area, icon:Icons.location_on),
      const SizedBox(height:8),
      Q8Field(hint:'العنوان', controller:_address, icon:Icons.home),
      const SizedBox(height:16),
      Q8Button(label:'حفظ التغييرات', isLoading:_loading, onTap:_save),
      const SizedBox(height:20),
    ]),
  );

  Future<void> _save() async {
    setState(()=>_loading=true);
    try {
      await APIService.instance.updateProfile({
        'contact_method':_contact, 'delivery_method':_delivery,
        'delivery_area':_area.text, 'delivery_address':_address.text,
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {}
    if (mounted) setState(()=>_loading=false);
  }
}
