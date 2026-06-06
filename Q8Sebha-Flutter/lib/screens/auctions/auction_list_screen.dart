import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../main.dart';
import '../../widgets/common_widgets.dart';
import 'auction_detail_screen.dart';
import 'create_auction_screen.dart';

class AuctionListScreen extends StatefulWidget {
  const AuctionListScreen({super.key});
  @override State<AuctionListScreen> createState() => _AuctionListScreenState();
}

class _AuctionListScreenState extends State<AuctionListScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<AuctionProvider>().fetchAuctions());
    _ticker = Timer.periodic(const Duration(seconds:1), (_) { if (mounted) setState((){}); });
  }

  @override void dispose() { _ticker?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final vm   = context.watch<AuctionProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar:AppBar(
        title:const Text('المزاد 🔨'),
        actions:[
          if (!auth.isGuest) IconButton(
            icon:const Icon(Icons.add_circle_outline, color:Colors.white),
            onPressed:() async {
              await Navigator.push(context, MaterialPageRoute(builder:(_)=>const CreateAuctionScreen()));
              if (context.mounted) context.read<AuctionProvider>().fetchAuctions();
            },
          ),
        ],
      ),
      body:vm.isLoading
        ? const LoadingBody()
        : vm.auctions.isEmpty
          ? const EmptyState(emoji:'🔨', message:'لا توجد مزادات نشطة')
          : RefreshIndicator(
              onRefresh:()=>vm.fetchAuctions(),
              child:ListView.builder(
                padding:const EdgeInsets.all(16),
                itemCount:vm.auctions.length,
                itemBuilder:(_, i) => _AuctionCard(
                  auction:vm.auctions[i],
                  onTap:()=>Navigator.push(context, MaterialPageRoute(
                      builder:(_)=>AuctionDetailScreen(auctionId:vm.auctions[i].id))),
                ),
              ),
            ),
    );
  }
}

// ─── بطاقة المزاد ─────────────────────────────────────────────────────────
class _AuctionCard extends StatelessWidget {
  final Auction auction;
  final VoidCallback onTap;
  const _AuctionCard({required this.auction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = auction.timeRemaining.inSeconds;
    final timerColor = t < 60 ? Colors.red : t < 300 ? Colors.orange : AppTheme.primary;

    return GestureDetector(
      onTap:onTap,
      child:Card(
        margin:const EdgeInsets.only(bottom:16),
        child:Padding(
          padding:const EdgeInsets.all(14),
          child:Column(crossAxisAlignment:CrossAxisAlignment.end, children:[
            Row(children:[
              // عداد
              Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                Row(children:[
                  Icon(Icons.timer, color:timerColor, size:14),
                  const SizedBox(width:4),
                  Text(auction.countdownString,
                    style:TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:13,color:timerColor)),
                ]),
                const SizedBox(height:4),
                Text('${auction.bidsCount} مزايدة',
                  style:const TextStyle(fontFamily:'Tajawal',fontSize:12,color:Colors.grey)),
              ]),
              const Spacer(),
              // صورة
              ClipRRect(
                borderRadius:BorderRadius.circular(10),
                child:auction.imageUrls.isEmpty
                  ? Container(width:70,height:70,color:Colors.grey.shade100,
                      child:const Center(child:Text('📿',style:TextStyle(fontSize:32))))
                  : Image.network('http://localhost:3000/uploads/${auction.primaryImage}',
                      width:70,height:70,fit:BoxFit.cover,
                      errorBuilder:(_,__,___)=>const Center(child:Text('📿',style:TextStyle(fontSize:32)))),
              ),
            ]),
            const SizedBox(height:10),
            Text(auction.title,
              style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:16),
              textAlign:TextAlign.right),
            const SizedBox(height:8),
            // شريط السعر
            Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
              Text(auction.maxPriceFormatted,
                style:const TextStyle(fontFamily:'Tajawal',fontSize:12,color:Colors.grey)),
              Text(auction.currentPriceFormatted,
                style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:15,color:AppTheme.primary)),
            ]),
            const SizedBox(height:4),
            PriceRangeBar(fraction:auction.progressFraction),
            if (auction.sellerTerms != null && auction.sellerTerms!.isNotEmpty) ...[
              const SizedBox(height:8),
              Text('📋 ${auction.sellerTerms}',
                style:const TextStyle(fontFamily:'Tajawal',fontSize:12,color:Colors.grey),
                maxLines:2, textAlign:TextAlign.right),
            ],
          ]),
        ),
      ),
    );
  }
}
