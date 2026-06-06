import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import '../../main.dart';

class CreateAuctionScreen extends StatefulWidget {
  const CreateAuctionScreen({super.key});
  @override State<CreateAuctionScreen> createState() => _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends State<CreateAuctionScreen> {
  final _title   = TextEditingController();
  final _desc    = TextEditingController();
  final _start   = TextEditingController();
  final _max     = TextEditingController();
  final _terms   = TextEditingController();
  double _durMin = 60;
  bool _loading  = false;
  String? _error;

  // ─── الصور ───────────────────────────────────────────────────
  final _picker = ImagePicker();
  final List<XFile>      _pickedFiles = [];
  final List<Uint8List>  _previews    = [];

  static const _maxImages = 6;

  static const _presets = [
    {'label':'10 د','v':10.0},{'label':'30 د','v':30.0},
    {'label':'ساعة','v':60.0},{'label':'3 س','v':180.0},
    {'label':'6 س','v':360.0},{'label':'12 س','v':720.0},{'label':'24 س','v':1440.0},
  ];

  String _formatDur(double m) {
    final mins = m.toInt();
    if (mins < 60) return '$mins دقيقة';
    final h = mins ~/ 60; final r = mins % 60;
    return r == 0 ? '$h ساعة' : '$h س و$r د';
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _pickedFiles.length;
    if (remaining <= 0) return;
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 80, limit: remaining);
      if (picked.isEmpty) return;
      for (final f in picked) {
        final bytes = await f.readAsBytes();
        setState(() { _pickedFiles.add(f); _previews.add(bytes); });
      }
    } catch (e) {
      setState(() => _error = 'تعذّر فتح المعرض');
    }
  }

  void _removeImage(int i) => setState(() { _pickedFiles.removeAt(i); _previews.removeAt(i); });

  @override
  Widget build(BuildContext context) {
    final sp = double.tryParse(_start.text) ?? 0;
    final mp = double.tryParse(_max.text)   ?? 0;
    final fraction = mp > sp ? (sp / mp).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة مزاد جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [

          // ─── قسم الصور ────────────────────────────────────────
          _ImagePickerSection(
            previews:    _previews,
            pickedCount: _pickedFiles.length,
            maxImages:   _maxImages,
            onAdd:       _pickImages,
            onRemove:    _removeImage,
          ),
          const SizedBox(height:16),

          Q8Field(hint:'عنوان المسباح', controller:_title, icon:Icons.title),
          const SizedBox(height:12),
          Q8Field(hint:'الوصف والمواصفات', controller:_desc, icon:Icons.description),
          const SizedBox(height:12),
          Q8Field(hint:'السعر الابتدائي (د.ك)', controller:_start, icon:Icons.tag, keyboard:TextInputType.number),
          const SizedBox(height:12),
          Q8Field(hint:'الحد الأعلى — أقصاه 4000 د.ك', controller:_max, icon:Icons.arrow_upward, keyboard:TextInputType.number),
          const SizedBox(height:16),

          // ─── مدة المزاد ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color:Colors.grey.shade50, borderRadius:BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('مدة المزاد', style:TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:15)),
              const SizedBox(height:8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_formatDur(_durMin),
                  style: const TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w700,fontSize:14,color:AppTheme.primary)),
                const SizedBox(),
              ]),
              Slider(
                value:_durMin, min:1, max:1440, divisions:143,
                activeColor:AppTheme.primary,
                onChanged:(v) => setState(()=>_durMin=v),
              ),
              Wrap(spacing:8, children:_presets.map((p) => GestureDetector(
                onTap: () => setState(()=>_durMin=p['v'] as double),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal:10, vertical:5),
                  decoration: BoxDecoration(
                    color: (_durMin-(p['v'] as double)).abs()<0.1 ? AppTheme.primary : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12)),
                  child: Text(p['label'] as String,
                    style: TextStyle(fontFamily:'Tajawal', fontSize:12,
                      color: (_durMin-(p['v'] as double)).abs()<0.1 ? Colors.white : Colors.black87)),
                ),
              )).toList()),
            ]),
          ),
          const SizedBox(height:12),
          Q8Field(hint:'شروط البيع (اختياري)', controller:_terms, icon:Icons.rule),
          const SizedBox(height:12),

          // ─── شريط السعر ───────────────────────────────────────
          if (sp > 0 && mp > sp) Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color:Colors.grey.shade50, borderRadius:BorderRadius.circular(12)),
            child: Column(crossAxisAlignment:CrossAxisAlignment.end, children: [
              const Text('نطاق السعر', style:TextStyle(fontFamily:'Tajawal',fontWeight:FontWeight.w600,fontSize:14)),
              const SizedBox(height:8),
              PriceRangeBar(fraction:fraction),
              const SizedBox(height:4),
              Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
                Text('${mp.toStringAsFixed(0)} د.ك', style:const TextStyle(fontFamily:'Tajawal',fontSize:12,color:Colors.grey)),
                Text('${sp.toStringAsFixed(0)} د.ك', style:const TextStyle(fontFamily:'Tajawal',fontSize:12,color:Colors.grey)),
              ]),
            ]),
          ),
          const SizedBox(height:16),

          if (_error != null) ErrorBanner(_error!),

          Q8Button(label:'نشر المزاد 🔨', isLoading:_loading, onTap:_submit),
          const SizedBox(height:20),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    final sp = double.tryParse(_start.text);
    final mp = double.tryParse(_max.text);
    if (_title.text.isEmpty || sp == null || mp == null) {
      setState(() => _error = 'يرجى تعبئة جميع الحقول المطلوبة'); return;
    }
    if (mp > 4000) { setState(() => _error = 'الحد الأعلى لا يتجاوز 4000 د.ك'); return; }
    if (mp <= sp)  { setState(() => _error = 'الحد الأعلى يجب أن يكون أكبر من السعر الابتدائي'); return; }

    setState(() { _loading = true; _error = null; });
    try {
      // رفع الصور أولاً إن وُجدت
      List<String> imageUrls = [];
      if (_pickedFiles.isNotEmpty) {
        imageUrls = await APIService.instance.uploadImages(_pickedFiles);
      }

      await APIService.instance.createAuction({
        'title':_title.text, 'description':_desc.text,
        'starting_price':sp, 'max_price':mp,
        'duration_minutes':_durMin.toInt(),
        'seller_terms':_terms.text, 'bid_increment':1.0,
        'image_urls':imageUrls,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:Text('✅ تم نشر المزاد', style:TextStyle(fontFamily:'Tajawal')),
            backgroundColor:Colors.green));
        Navigator.pop(context);
      }
    } on APIError catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'خطأ: ${e.toString()}');
    }
    if (mounted) setState(() => _loading = false);
  }
}

// ─── Image Picker Section ─────────────────────────────────────────────────────
class _ImagePickerSection extends StatelessWidget {
  final List<Uint8List> previews;
  final int pickedCount;
  final int maxImages;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _ImagePickerSection({
    required this.previews, required this.pickedCount,
    required this.maxImages, required this.onAdd, required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('$pickedCount / $maxImages صور',
          style: const TextStyle(fontFamily:'Tajawal', fontSize:13, color:Colors.grey)),
        const Text('صور المسباح', style: TextStyle(fontFamily:'Tajawal', fontWeight:FontWeight.w700, fontSize:15)),
      ]),
      const SizedBox(height:10),
      SizedBox(
        height: 110,
        child: ListView(
          scrollDirection: Axis.horizontal,
          reverse: true,         // RTL: الزر على اليمين
          children: [
            // زر الإضافة
            if (pickedCount < maxImages)
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width:90, height:90,
                  margin: const EdgeInsets.only(left:8),
                  decoration: BoxDecoration(
                    border: Border.all(color:AppTheme.primary, width:1.5, style:BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.primary.withOpacity(0.06),
                  ),
                  child: const Column(mainAxisAlignment:MainAxisAlignment.center, children:[
                    Icon(Icons.add_photo_alternate_outlined, color:AppTheme.primary, size:30),
                    SizedBox(height:4),
                    Text('أضف صورة', style:TextStyle(fontFamily:'Tajawal', fontSize:11, color:AppTheme.primary)),
                  ]),
                ),
              ),
            // الصور المختارة
            ...List.generate(previews.length, (i) => _ThumbItem(
              bytes: previews[i],
              onRemove: () => onRemove(i),
            )).reversed,
          ],
        ),
      ),
      if (pickedCount == 0)
        const Padding(
          padding: EdgeInsets.only(top:6),
          child: Text('الصور اختيارية لكن تزيد الثقة 📸',
            style: TextStyle(fontFamily:'Tajawal', fontSize:12, color:Colors.grey),
            textAlign: TextAlign.right),
        ),
    ]);
  }
}

class _ThumbItem extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onRemove;
  const _ThumbItem({required this.bytes, required this.onRemove});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        width:90, height:90,
        margin: const EdgeInsets.only(left:8, top:4, right:4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(image:MemoryImage(bytes), fit:BoxFit.cover),
        ),
      ),
      Positioned(
        top:0, right:0,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            decoration: const BoxDecoration(color:Colors.red, shape:BoxShape.circle),
            padding: const EdgeInsets.all(3),
            child: const Icon(Icons.close, color:Colors.white, size:14),
          ),
        ),
      ),
    ],
  );
}
