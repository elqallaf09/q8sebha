import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/models.dart';
import '../../main.dart';
import '../../widgets/common_widgets.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String? _category;
  final _search = TextEditingController();

  static const _cats = [
    {'emoji':'🔍','name':'الكل','slug':null},
    {'emoji':'📿','name':'مسابيح','slug':'misbaha'},
    {'emoji':'💍','name':'خواتم','slug':'rings'},
    {'emoji':'💎','name':'أحجار','slug':'gemstones'},
    {'emoji':'🏺','name':'تحف','slug':'antiques'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<ProductProvider>().fetchProducts());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductProvider>();
    return Scaffold(
      appBar: AppBar(title:const Text('Q8Sebha 📿'), centerTitle:true),
      body: Column(children:[
        // بحث
        Padding(
          padding:const EdgeInsets.fromLTRB(16,12,16,0),
          child:TextField(
            controller:_search, textAlign:TextAlign.right,
            decoration:InputDecoration(
              hintText:'ابحث عن مسباح...',
              suffixIcon:IconButton(icon:const Icon(Icons.search), onPressed:_doSearch),
              prefixIcon:_search.text.isNotEmpty?IconButton(icon:const Icon(Icons.close),onPressed:(){_search.clear();_doSearch();}):null,
            ),
            onSubmitted:(_)=>_doSearch(),
          ),
        ),
        // فئات
        SizedBox(height:52, child:ListView.builder(
          scrollDirection:Axis.horizontal, padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),
          itemCount:_cats.length,
          itemBuilder:(_, i) {
            final c = _cats[i];
            final isSelected = _category == c['slug'];
            return GestureDetector(
              onTap:(){ setState(()=>_category=c['slug'] as String?); context.read<ProductProvider>().fetchProducts(category:_category); },
              child:Container(
                margin:const EdgeInsets.only(left:8),
                padding:const EdgeInsets.symmetric(horizontal:14,vertical:6),
                decoration:BoxDecoration(
                  color:isSelected?AppTheme.primary:Colors.grey.shade100,
                  borderRadius:BorderRadius.circular(20)),
                child:Row(children:[
                  Text(c['emoji'] as String, style:const TextStyle(fontSize:14)),
                  const SizedBox(width:4),
                  Text(c['name'] as String,
                    style:TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w600,fontSize:13,
                      color:isSelected?Colors.white:Colors.black87)),
                ]),
              ),
            );
          },
        )),
        // محتوى
        Expanded(child: vm.isLoading
          ? const LoadingBody()
          : vm.products.isEmpty
            ? const EmptyState(emoji:'📦', message:'لا توجد منتجات')
            : RefreshIndicator(
                onRefresh:()=>context.read<ProductProvider>().fetchProducts(category:_category),
                child:GridView.builder(
                  padding:const EdgeInsets.all(16),
                  gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:2, crossAxisSpacing:14, mainAxisSpacing:14, childAspectRatio:0.68),
                  itemCount:vm.products.length,
                  itemBuilder:(_, i) => _ProductCard(product:vm.products[i]),
                ),
              ),
        ),
      ]),
    );
  }

  void _doSearch() => context.read<ProductProvider>().fetchProducts(category:_category, search:_search.text);
}

// ─── بطاقة المنتج ─────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap:()=>Navigator.push(context, MaterialPageRoute(builder:(_)=>ProductDetailScreen(productId:product.id))),
    child:Card(
      child:Column(crossAxisAlignment:CrossAxisAlignment.stretch, children:[
        Expanded(
          flex:3,
          child:Stack(children:[
            ClipRRect(
              borderRadius:const BorderRadius.vertical(top:Radius.circular(16)),
              child:product.imageUrls.isEmpty
                ? Container(color:Colors.grey.shade50, child:Center(child:Text(product.emoji, style:const TextStyle(fontSize:50))))
                : Image.network('http://10.0.2.2:3000/uploads/${product.primaryImage}',
                    fit:BoxFit.cover, width:double.infinity,
                    errorBuilder:(_,__,___)=>Center(child:Text(product.emoji, style:const TextStyle(fontSize:50)))),
            ),
            if (product.badge != null) Positioned(top:8, right:8,
              child:Container(
                padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
                decoration:BoxDecoration(color:Colors.red, borderRadius:BorderRadius.circular(8)),
                child:Text(product.badge!, style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.bold)),
              )),
          ]),
        ),
        Expanded(flex:2,child:Padding(
          padding:const EdgeInsets.all(10),
          child:Column(crossAxisAlignment:CrossAxisAlignment.end, mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
            Text(product.name, style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w600,fontSize:13), maxLines:2, textAlign:TextAlign.right),
            Text(product.priceFormatted, style:const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:14,color:AppTheme.primary)),
          ]),
        )),
      ]),
    ),
  );
}
