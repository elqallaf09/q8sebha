import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';

const _kDark   = Color(0xFF1A1A2E);
const _kDeep   = Color(0xFF16213E);
const _kGold   = Color(0xFFB8963E);
const _kGoldLt = Color(0xFFD4A853);
const _kBg     = Color(0xFFF8F5EE);
const _kGrey   = Color(0xFF8E8E93);
const _kBorder = Color(0xFFE8E0D0);

class InvoiceService {
  static InvoiceService get instance => _i;
  static final _i = InvoiceService._();
  InvoiceService._();

  Future<void> previewInvoice(Order order, BuildContext context) async {
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvoicePreviewScreen(order: order)),
    );
  }

  Future<void> shareInvoice(Order order) async {
    final text = _buildText(order);
    await Share.share(text, subject: 'فاتورة ${order.orderNumber} — مسابيح لايقر');
  }

  String _buildText(Order order) {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    final buf = StringBuffer();
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('📿  مسابيح لايقر  📿');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('رقم الطلب: ${order.orderNumber}');
    buf.writeln('التاريخ: $dateStr');
    buf.writeln('الحالة: ${order.statusDisplay}');
    buf.writeln('');
    if ((order.buyerName ?? '').isNotEmpty) buf.writeln('العميل: ${order.buyerName}');
    if ((order.buyerPhone ?? '').isNotEmpty) buf.writeln('الهاتف: ${order.buyerPhone}');
    if ((order.deliveryAddress ?? '').isNotEmpty) buf.writeln('العنوان: ${order.deliveryAddress}');
    buf.writeln('');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('المنتجات:');
    if (order.isCartOrder && order.items.isNotEmpty) {
      for (final item in order.items) {
        buf.writeln('  ${item.productEmoji} ${item.productName}');
        buf.writeln('  الكمية: ${item.quantity} x ${item.unitPrice.toStringAsFixed(3)} = ${item.totalPrice.toStringAsFixed(3)} KD');
      }
    } else {
      final emoji = order.productEmoji ?? '📿';
      final name  = order.productName ?? 'منتج';
      buf.writeln('  $emoji $name');
    }
    buf.writeln('');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('الإجمالي: ${order.totalPrice.toStringAsFixed(3)} KD');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    if ((order.notes ?? '').isNotEmpty) buf.writeln('ملاحظات: ${order.notes}');
    buf.writeln('');
    buf.writeln('شكراً لتسوقكم معنا');
    return buf.toString();
  }
}

// ─── شاشة المعاينة ────────────────────────────────────────────────────────
class InvoicePreviewScreen extends StatelessWidget {
  final Order order;
  const InvoicePreviewScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDark,
      appBar: AppBar(
        backgroundColor: _kDeep,
        foregroundColor: Colors.white,
        title: const Text(
          'الفاتورة',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: _kGold),
            tooltip: 'مشاركة',
            onPressed: () => InvoiceService.instance.shareInvoice(order),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _InvoiceCard(order: order),
      ),
    );
  }
}

// ─── بطاقة الفاتورة ───────────────────────────────────────────────────────
class _InvoiceCard extends StatelessWidget {
  final Order order;
  const _InvoiceCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final now     = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    return Container(
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildMeta(dateStr),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildTable(),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildTotal(),
          ),
          if ((order.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildNotes(),
            ),
          ],
          const SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kDark, _kDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: _kGold,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _kGold.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(child: Text('📿', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('INVOICE / فاتورة',
                  style: TextStyle(
                    fontFamily: 'Tajawal', fontSize: 11,
                    color: _kGold, letterSpacing: 1.2)),
                SizedBox(height: 4),
                Text('مسابيح لايقر',
                  style: TextStyle(
                    fontFamily: 'Tajawal', fontSize: 22,
                    fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeta(String dateStr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _infoBox('معلومات الفاتورة', [
            _row('رقم',   order.orderNumber),
            _row('تاريخ', dateStr),
            _row('حالة',  order.statusDisplay),
          ])),
          const SizedBox(width: 12),
          Expanded(child: _infoBox('بيانات العميل', [
            if ((order.buyerName ?? '').isNotEmpty)
              _row('الاسم',   order.buyerName!),
            if ((order.buyerPhone ?? '').isNotEmpty)
              _row('الهاتف',  order.buyerPhone!),
            if ((order.deliveryAddress ?? '').isNotEmpty)
              _row('العنوان', order.deliveryAddress!),
          ])),
        ],
      ),
    );
  }

  Widget _infoBox(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title,
            style: const TextStyle(
              fontFamily: 'Tajawal', fontSize: 11,
              fontWeight: FontWeight.w700, color: _kGold)),
          const Divider(color: _kBorder, height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(value,
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: _kDark),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 4),
          Text(label,
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: _kGrey)),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final List<List<String>> rows;
    if (order.isCartOrder && order.items.isNotEmpty) {
      rows = order.items.map((i) => [
        i.totalPrice.toStringAsFixed(3),
        i.unitPrice.toStringAsFixed(3),
        '${i.quantity}',
        '${i.productEmoji} ${i.productName}',
      ]).toList();
    } else {
      rows = [[
        order.totalPrice.toStringAsFixed(3),
        order.totalPrice.toStringAsFixed(3),
        '1',
        '${order.productEmoji ?? "📿"} ${order.productName ?? "منتج"}',
      ]];
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            color: _kDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(
            children: [
              _th('الإجمالي', 2),
              _th('السعر',    2),
              _th('الكمية',   1),
              _th('المنتج',   4),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
          child: Column(
            children: rows.asMap().entries.map((e) {
              final even = e.key % 2 == 0;
              final r    = e.value;
              return Container(
                color: even ? Colors.white : const Color(0xFFF8F5EE),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    _td(r[0], 2, bold: true),
                    _td(r[1], 2),
                    _td(r[2], 1),
                    _td(r[3], 4, align: TextAlign.end),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _th(String text, int flex) => Expanded(
    flex: flex,
    child: Text(text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Tajawal', fontSize: 11,
        fontWeight: FontWeight.w700, color: Colors.white)),
  );

  Widget _td(String text, int flex, {bool bold = false, TextAlign align = TextAlign.center}) =>
    Expanded(
      flex: flex,
      child: Text(text,
        textAlign: align,
        style: TextStyle(
          fontFamily: 'Tajawal', fontSize: 11,
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          color: _kDark)),
    );

  Widget _buildTotal() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kDark, _kDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _kDark.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${order.totalPrice.toStringAsFixed(3)} KD',
              style: const TextStyle(
                fontFamily: 'Tajawal', fontSize: 16,
                fontWeight: FontWeight.w900, color: _kGoldLt)),
            const Text('الإجمالي الكلي',
              style: TextStyle(
                fontFamily: 'Tajawal', fontSize: 12,
                fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: _kGold),
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFFFF8E8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('ملاحظات',
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 10,
              fontWeight: FontWeight.w700, color: _kGold)),
          const SizedBox(height: 6),
          Text(order.notes!,
            textAlign: TextAlign.end,
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: _kDark)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _kBorder)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('شكراً لتسوقكم معنا 🙏',
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: _kGrey)),
          Text('مسابيح لايقر',
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 11,
              fontWeight: FontWeight.w700, color: _kDark)),
        ],
      ),
    );
  }
}
