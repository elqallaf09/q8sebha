import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../main.dart';
import '../../config/app_config.dart';
import '../../widgets/common_widgets.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<ProductProvider>().fetchProduct(widget.productId));
  }

  @override
  Widget build(BuildContext context) {
    final vm   = context.watch<ProductProvider>();
    final auth = context.watch<AuthProvider>();
    final p    = vm.selectedProduct;

    if (vm.isLoading || p == null) return const Scaffold(body:LoadingBody());

    return Scaffold(
      appBar:AppBar(title:Text(p.name)),
      body:SingleChildScrollView(
        child:Column(children:[
          // صورة
          SizedBox(height:280, child:Stack(children:[
            p.imageUrls.isEmpty
              ? Container(color:Colors.grey.shade100, child:Center(child:Text(p.emoji,style:const TextStyle(fontSize:100))))
              : Image.network(AppConfig.imageUrl(p.primaryImage),
                  width:double.infinity, height:280, fit:BoxFit.cover,
                  errorBuilder:(_,__,___)=>Center(child:Text(p.emoji,style:const TextStyle(fontSize:100)))),
            if (p.badge!=null) Positioned(top:12,right:12,
              child:Container(
                padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),
                decoration:BoxDecoration(color:Colors.red,borderRadius:BorderRadius.circular(10)),
                child:Text(p.badge!,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
              )),
          ])),

          Padding(padding:const EdgeInsets.all(20), child:Column(crossAxisAlignment:CrossAxisAlignment.end, children:[
            // اسم وسعر
            Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
              Text(p.priceFormatted,style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:26,color:AppTheme.primary)),
              Text(p.name,style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:20)),
            ]),
            const SizedBox(height:16),

            // مواصفات
            if (p.beadCount!=null || p.material!=null || p.weightGrams!=null)
              Container(
                padding:const EdgeInsets.all(14), margin:const EdgeInsets.only(bottom:16),
                decoration:BoxDecoration(color:Colors.grey.shade50,borderRadius:BorderRadius.circular(12)),
                child:Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
                  const Text('المواصفات',style:TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:16)),
                  const Divider(),
                  if(p.beadCount!=null) _spec('عدد الحبات','${p.beadCount} حبة'),
                  if(p.beadSizeMm!=null) _spec('حجم الحبة','${p.beadSizeMm} مم'),
                  if(p.weightGrams!=null) _spec('الوزن','${p.weightGrams} غ'),
                  if(p.material!=null) _spec('الخامة',p.material!),
                  if(p.originCountry!=null) _spec('بلد المنشأ',p.originCountry!),
                ]),
              ),

            if (p.description!=null) ...[
              Text(p.description!,style:const TextStyle(fontFamily:'Tajawal',fontSize:15,color:Colors.grey),textAlign:TextAlign.right),
              const SizedBox(height:16),
            ],

            // ملاحظات
            const Text('ملاحظات (اختياري)',style:TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w600,fontSize:14)),
            const SizedBox(height:8),
            TextField(controller:_notes, maxLines:3, textAlign:TextAlign.right,
              decoration:const InputDecoration(hintText:'أضف ملاحظاتك...')),
            const SizedBox(height:20),

            if (vm.errorMessage!=null) ErrorBanner(vm.errorMessage!),

            // زر الشراء
            Q8Button(
              label:'شراء الآن 🛒',
              isLoading:vm.isLoading,
              onTap: auth.isGuest
                ? ()=>_showGuestAlert(context)
                : ()=>_confirmPurchase(context, vm, auth),
            ),
          ])),
        ]),
      ),
    );
  }

  Widget _spec(String label, String value) => Padding(
    padding:const EdgeInsets.symmetric(vertical:4),
    child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      Text(value,style:const TextStyle(fontFamily:'Tajawal',fontSize:14)),
      Text(label,style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w600,fontSize:14)),
    ]),
  );

  void _showGuestAlert(BuildContext context) => showDialog(
    context:context,
    builder:(_)=>AlertDialog(
      title:const Text('مستخدم ضيف',textAlign:TextAlign.right,style:TextStyle(fontFamily:'Tajawal')),
      content:const Text('يجب تسجيل الدخول للشراء',textAlign:TextAlign.right,style:TextStyle(fontFamily:'Tajawal')),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(context), child:const Text('إلغاء')),
        ElevatedButton(
          onPressed:(){Navigator.pop(context); context.read<AuthProvider>().appState=AppState.auth;},
          child:const Text('تسجيل الدخول')),
      ],
    ),
  );

  void _confirmPurchase(BuildContext ctx, ProductProvider vm, AuthProvider auth) {
    showModalBottomSheet(context:ctx, builder:(_)=>SafeArea(
      child:Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Text('تأكيد الشراء',style:TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:18)),
        const SizedBox(height:8),
        const Text('سيصلك رابط الدفع عبر الواتساب',style:TextStyle(fontFamily:'Tajawal',color:Colors.grey)),
        const SizedBox(height:20),
        Q8Button(label:'تأكيد — ${vm.selectedProduct?.priceFormatted}', onTap:()async{
          Navigator.pop(ctx);
          await vm.buyProduct(vm.selectedProduct!.id, notes:_notes.text);
          if (vm.orderSuccess && ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content:Text('✅ تم الطلب! سيصلك رابط الدفع عبر الواتساب',textAlign:TextAlign.right,
                style:TextStyle(fontFamily:'Tajawal')), backgroundColor:Colors.green));
          }
        }),
        const SizedBox(height:8),
        TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء',style:TextStyle(color:Colors.grey))),
      ])),
    ));
  }
}
