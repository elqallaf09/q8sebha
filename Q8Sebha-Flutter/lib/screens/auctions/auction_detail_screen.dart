import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../main.dart';
import '../../widgets/common_widgets.dart';

class AuctionDetailScreen extends StatefulWidget {
  final int auctionId;
  const AuctionDetailScreen({super.key, required this.auctionId});
  @override State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  Timer? _ticker;
  final _payLink = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<AuctionProvider>().fetchAuction(widget.auctionId));
    _ticker = Timer.periodic(const Duration(seconds:1), (_) { if(mounted) setState((){}); });
  }

  @override void dispose() { _ticker?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final vm   = context.watch<AuctionProvider>();
    final auth = context.watch<AuthProvider>();
    final a    = vm.selectedAuction;

    if (vm.isLoading && a == null) return const Scaffold(body:LoadingBody());
    if (a == null) return const Scaffold(body:Center(child:Text('خطأ في التحميل')));

    final t = a.timeRemaining.inSeconds;
    final timerColor = t < 60 ? Colors.red : t < 300 ? Colors.orange : AppTheme.primary;

    return Scaffold(
      appBar:AppBar(title:Text(a.title, overflow:TextOverflow.ellipsis)),
      body:SingleChildScrollView(
        child:Column(children:[
          // صورة
          SizedBox(height:260,child:Stack(children:[
            a.imageUrls.isEmpty
              ? Container(color:Colors.grey.shade100,child:const Center(child:Text('📿',style:TextStyle(fontSize:100))))
              : Image.network('http://10.0.2.2:3000/uploads/${a.primaryImage}',
                  width:double.infinity,height:260,fit:BoxFit.cover,
                  errorBuilder:(_,__,___)=>const Center(child:Text('📿',style:TextStyle(fontSize:100)))),
            // حالة وعداد
            Positioned(bottom:0,left:0,right:0,
              child:Container(
                padding:const EdgeInsets.symmetric(horizontal:16,vertical:10),
                color:Colors.black54,
                child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
                  Container(
                    padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
                    decoration:BoxDecoration(color:timerColor.withOpacity(0.9),borderRadius:BorderRadius.circular(8)),
                    child:Row(children:[
                      const Icon(Icons.timer,color:Colors.white,size:14),
                      const SizedBox(width:4),
                      Text(a.countdownString,style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:13,color:Colors.white)),
                    ]),
                  ),
                  Container(
                    padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
                    decoration:BoxDecoration(
                      color:(a.isActive?Colors.green:Colors.red).withOpacity(0.9),
                      borderRadius:BorderRadius.circular(8)),
                    child:Text(a.isActive?'🟢 نشط':'🔴 انتهى',
                      style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:13,color:Colors.white)),
                  ),
                ]),
              )),
          ])),

          Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
            // سعر
            Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
              Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                const Text('السعر الحالي',style:TextStyle(fontFamily:'Tajawal',fontSize:12,color:Colors.grey)),
                Text(a.currentPriceFormatted,
                  style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:28,color:AppTheme.primary)),
              ]),
              Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
                Text('${a.bidsCount} مزايدة',style:const TextStyle(fontFamily:'Tajawal',fontSize:13,color:Colors.grey)),
                Text('الحد الأعلى: ${a.maxPriceFormatted}',style:const TextStyle(fontFamily:'Tajawal',fontSize:12,color:Colors.grey)),
              ]),
            ]),
            const SizedBox(height:8),
            PriceRangeBar(fraction:a.progressFraction),
            const SizedBox(height:4),
            Text('السعر الابتدائي: ${a.startingPrice.toStringAsFixed(3)} د.ك',
              style:const TextStyle(fontFamily:'Tajawal',fontSize:12,color:Colors.grey)),
            const SizedBox(height:16),

            if (a.sellerName != null) _infoBox('👤 البائع', a.sellerName!),
            if (a.sellerTerms != null && a.sellerTerms!.isNotEmpty) _infoBox('📋 شروط البائع', a.sellerTerms!),

            if (vm.errorMessage != null) ...[
              const SizedBox(height:8), ErrorBanner(vm.errorMessage!),
            ],
            const SizedBox(height:16),

            // زر المزايدة
            if (a.isActive) ...[
              if (auth.isGuest)
                Q8Button(label:'سجّل الدخول للمزايدة', color:Colors.grey,
                  onTap:()=>context.read<AuthProvider>().appState=AppState.auth)
              else
                Q8Button(
                  label:'زايد الآن +${a.bidIncrement.toStringAsFixed(3)} د.ك 🔨',
                  isLoading:vm.isLoading,
                  onTap:()=>_confirmBid(context, vm, a),
                ),
            ],

            // البائع: إرسال رابط دفع
            if (!a.isActive && a.sellerId == auth.currentUser?.id && a.winnerId != null) ...[
              const SizedBox(height:16),
              Container(
                padding:const EdgeInsets.all(14),
                decoration:BoxDecoration(color:Colors.orange.shade50,borderRadius:BorderRadius.circular(12)),
                child:Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
                  Text('الفائز: ${a.winnerName ?? "#${a.winnerId}"}',
                    style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w600,fontSize:14)),
                  const SizedBox(height:10),
                  TextField(controller:_payLink,textAlign:TextAlign.right,
                    decoration:const InputDecoration(hintText:'رابط الدفع (واتساب/كاشير...)')),
                  const SizedBox(height:10),
                  Q8Button(label:'إرسال رابط الدفع للفائز', color:Colors.green,
                    onTap:()async{
                      final ok = await vm.sendPaymentLink(a.id, _payLink.text);
                      if (ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content:Text('✅ تم إرسال الرابط',textAlign:TextAlign.right,style:TextStyle(fontFamily:'Tajawal'))));
                    }),
                  const SizedBox(height:8),
                  Q8Button(label:'إبلاغ عن عدم الدفع ⚠️', color:Colors.red,
                    onTap:()=>_confirmReport(context, vm, a.id)),
                ]),
              ),
            ],

            // آخر المزايدات
            if (vm.bids.isNotEmpty) ...[
              const SizedBox(height:20),
              const Text('آخر المزايدات',
                style:TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:16)),
              const Divider(),
              ...vm.bids.take(10).map((bid) => Container(
                margin:const EdgeInsets.only(bottom:8),
                padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
                decoration:BoxDecoration(color:Colors.grey.shade50,borderRadius:BorderRadius.circular(10)),
                child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
                  Text(bid.amountFormatted,
                    style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:14,color:AppTheme.primary)),
                  Row(children:[
                    Text(bid.bidderName ?? 'مجهول',
                      style:const TextStyle(fontFamily:'Tajawal',fontSize:14)),
                    const SizedBox(width:6),
                    const Icon(Icons.person_outline, size:16, color:Colors.grey),
                  ]),
                ]),
              )),
            ],
          ])),
        ]),
      ),
    );
  }

  Widget _infoBox(String title, String content) => Container(
    width:double.infinity, margin:const EdgeInsets.only(bottom:10),
    padding:const EdgeInsets.all(12),
    decoration:BoxDecoration(color:Colors.grey.shade50,borderRadius:BorderRadius.circular(10)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
      Text(title,style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:14)),
      const SizedBox(height:4),
      Text(content,style:const TextStyle(fontFamily:'Tajawal',fontSize:14,color:Colors.grey),textAlign:TextAlign.right),
    ]),
  );

  void _confirmBid(BuildContext ctx, AuctionProvider vm, auction) {
    final nextAmount = (auction.currentPrice + auction.bidIncrement).toStringAsFixed(3);
    showDialog(context:ctx, builder:(_)=>AlertDialog(
      title:const Text('تأكيد المزايدة',textAlign:TextAlign.right,style:TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700)),
      content:Text('سيتم المزايدة بـ $nextAmount د.ك',textAlign:TextAlign.right,style:const TextStyle(fontFamily:'Tajawal')),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء')),
        ElevatedButton(onPressed:()async{
          Navigator.pop(ctx);
          await vm.placeBid(auction.id, auction.currentPrice + auction.bidIncrement);
          if (vm.bidSuccess && ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content:Text('✅ تم تسجيل مزايدتك',style:TextStyle(fontFamily:'Tajawal')),backgroundColor:Colors.green));
        }, child:const Text('تأكيد')),
      ],
    ));
  }

  void _confirmReport(BuildContext ctx, AuctionProvider vm, int auctionId) {
    showDialog(context:ctx, builder:(_)=>AlertDialog(
      title:const Text('إبلاغ عن عدم الدفع',textAlign:TextAlign.right,style:TextStyle(fontFamily:'Tajawal',color:Colors.red,fontWeight:FontWeight.w700)),
      content:const Text('سيتم حظر المشتري من التطبيق. هل أنت متأكد؟',textAlign:TextAlign.right,style:TextStyle(fontFamily:'Tajawal')),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء')),
        ElevatedButton(
          style:ElevatedButton.styleFrom(backgroundColor:Colors.red),
          onPressed:()async{
            Navigator.pop(ctx);
            final ok = await vm.reportNonPayment(auctionId);
            if (ok && ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content:Text('تم الإبلاغ وحظر المشتري',style:TextStyle(fontFamily:'Tajawal')),backgroundColor:Colors.red));
          },
          child:const Text('إبلاغ وحظر')),
      ],
    ));
  }
}
