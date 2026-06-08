import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';

// ─── ألوان الفاتورة ─────────────────────────────────────────────────────────
const _cDark   = PdfColor.fromInt(0xFF1A1A2E);
const _cGold   = PdfColor.fromInt(0xFFB8963E);
const _cBg     = PdfColor.fromInt(0xFFF8F5EE);
const _cWhite  = PdfColors.white;
const _cGrey   = PdfColor.fromInt(0xFF8E8E93);
const _cBorder = PdfColor.fromInt(0xFFE8E0D0);

class InvoiceService {
  static InvoiceService get instance => _i;
  static final _i = InvoiceService._();
  InvoiceService._();

  // ─── توليد PDF ─────────────────────────────────────────────────────────────
  Future<Uint8List> buildBytes(Order order) async {
    final doc      = pw.Document();
    final font     = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    final now      = DateTime.now();
    final dateStr  = '${now.day}/${now.month}/${now.year}';

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Column(children: [
          _buildHeader('مسابيح لايقر', font, fontBold),
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _infoBox('معلومات الفاتورة', [
                  'رقم: ${order.orderNumber}',
                  'التاريخ: $dateStr',
                  'الحالة: ${order.statusDisplay}',
                ], font, fontBold),
                _infoBox('معلومات العميل', [
                  order.buyerName ?? 'عميل',
                  if ((order.buyerPhone ?? '').isNotEmpty) order.buyerPhone!,
                  if ((order.deliveryAddress ?? '').isNotEmpty) order.deliveryAddress!,
                ], font, fontBold),
              ],
            ),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(horizontal: 32),
            child: _itemsTable(order, font, fontBold),
          ),
          pw.SizedBox(height: 16),
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(horizontal: 32),
            child: _totals(order, font, fontBold),
          ),
          if ((order.notes ?? '').isNotEmpty)
            pw.Padding(
              padding: pw.EdgeInsets.fromLTRB(32, 16, 32, 0),
              child: _notesBox(order.notes!, font),
            ),
          pw.Spacer(),
          _buildFooter('مسابيح لايقر', font),
        ]),
      ),
    ));

    return doc.save();
  }

  // ─── هيدر ─────────────────────────────────────────────────────────────────
  pw.Widget _buildHeader(String store, pw.Font font, pw.Font bold) =>
    pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: pw.BoxDecoration(color: _cDark),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('INVOICE / فاتورة',
              style: pw.TextStyle(font: font, color: _cGold, fontSize: 11)),
            pw.SizedBox(height: 4),
            pw.Text(store,
              style: pw.TextStyle(font: bold, color: _cWhite, fontSize: 22)),
          ]),
          pw.Container(
            width: 56, height: 56,
            decoration: pw.BoxDecoration(
              color: _cGold,
              borderRadius: pw.BorderRadius.circular(12)),
            child: pw.Center(
              child: pw.Text('📿',
                style: pw.TextStyle(font: font, fontSize: 26)))),
        ],
      ),
    );

  // ─── صندوق المعلومات ───────────────────────────────────────────────────────
  pw.Widget _infoBox(String title, List<String> lines, pw.Font font, pw.Font bold) =>
    pw.Container(
      padding: pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _cBg,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _cBorder, width: 0.5)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Text(title,
          style: pw.TextStyle(font: bold, fontSize: 10, color: _cGold)),
        pw.Divider(color: _cBorder, height: 8),
        ...lines.where((l) => l.isNotEmpty).map((l) => pw.Padding(
          padding: pw.EdgeInsets.only(bottom: 2),
          child: pw.Text(l,
            style: pw.TextStyle(font: font, fontSize: 10, color: _cDark)))),
      ]),
    );

  // ─── جدول المنتجات ────────────────────────────────────────────────────────
  pw.Widget _itemsTable(Order order, pw.Font font, pw.Font bold) {
    final rows = order.isCartOrder && order.items.isNotEmpty
      ? order.items.map((i) => [
          '${i.totalPrice.toStringAsFixed(3)} د.ك',
          '${i.unitPrice.toStringAsFixed(3)} د.ك',
          '${i.quantity}',
          '${i.productEmoji} ${i.productName}',
        ]).toList()
      : [[
          '${order.totalPrice.toStringAsFixed(3)} د.ك',
          '${order.totalPrice.toStringAsFixed(3)} د.ك',
          '1',
          '${order.productEmoji ?? '📿'} ${order.productName ?? 'منتج'}',
        ]];

    return pw.Table(
      border: pw.TableBorder.all(color: _cBorder, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(4),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _cDark),
          children: ['الإجمالي','السعر','الكمية','المنتج'].map((h) =>
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: pw.Text(h, textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: bold, fontSize: 10, color: _cWhite)))).toList()),
        ...rows.asMap().entries.map((e) => pw.TableRow(
          decoration: pw.BoxDecoration(
            color: e.key % 2 == 0 ? _cWhite : _cBg),
          children: e.value.map((c) =>
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: pw.Text(c, textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: font, fontSize: 10, color: _cDark)))).toList())),
      ],
    );
  }

  // ─── الإجمالي ─────────────────────────────────────────────────────────────
  pw.Widget _totals(Order order, pw.Font font, pw.Font bold) =>
    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
      pw.Container(
        width: 220,
        decoration: pw.BoxDecoration(
          color: _cBg,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: _cBorder, width: 0.5)),
        child: pw.Column(children: [
          pw.Container(
            padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: pw.BoxDecoration(color: _cDark),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('${order.totalPrice.toStringAsFixed(3)} د.ك',
                  style: pw.TextStyle(font: bold, fontSize: 14, color: _cGold)),
                pw.Text('الإجمالي الكلي',
                  style: pw.TextStyle(font: bold, fontSize: 11, color: _cWhite)),
              ]),
          ),
        ]),
      ),
    ]);

  // ─── ملاحظات ──────────────────────────────────────────────────────────────
  pw.Widget _notesBox(String notes, pw.Font font) =>
    pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _cGold, width: 0.8),
        borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Text('ملاحظات',
          style: pw.TextStyle(font: font, fontSize: 9, color: _cGold)),
        pw.SizedBox(height: 4),
        pw.Text(notes,
          style: pw.TextStyle(font: font, fontSize: 10, color: _cDark)),
      ]),
    );

  // ─── فوتر ─────────────────────────────────────────────────────────────────
  pw.Widget _buildFooter(String store, pw.Font font) =>
    pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _cGold, width: 1))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('شكراً لتسوقكم معنا',
            style: pw.TextStyle(font: font, fontSize: 9, color: _cGrey)),
          pw.Text(store,
            style: pw.TextStyle(font: font, fontSize: 9, color: _cDark)),
        ],
      ),
    );

  // ─── معاينة داخل التطبيق ─────────────────────────────────────────────────
  Future<void> previewInvoice(Order order, BuildContext context) async {
    try {
      final bytes = await buildBytes(order);
      if (!context.mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => _InvoicePreviewScreen(
          orderNumber: order.orderNumber,
          bytes: bytes,
          order: order,
        ),
      ));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل إنشاء الفاتورة: $e',
            style: const TextStyle(fontFamily: 'Tajawal')),
          backgroundColor: Colors.red));
      }
    }
  }

  // ─── مشاركة ───────────────────────────────────────────────────────────────
  Future<void> shareInvoice(Order order, BuildContext context) async {
    try {
      final bytes = await buildBytes(order);
      final dir   = await getTemporaryDirectory();
      final file  = File('${dir.path}/invoice_${order.orderNumber}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'فاتورة ${order.orderNumber} — مسابيح لايقر',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل مشاركة الفاتورة: $e',
            style: const TextStyle(fontFamily: 'Tajawal')),
          backgroundColor: Colors.red));
      }
    }
  }
}

// ─── شاشة المعاينة ────────────────────────────────────────────────────────
class _InvoicePreviewScreen extends StatelessWidget {
  final String orderNumber;
  final Uint8List bytes;
  final Order order;
  const _InvoicePreviewScreen({
    required this.orderNumber,
    required this.bytes,
    required this.order,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF1A1A2E),
    appBar: AppBar(
      backgroundColor: const Color(0xFF1A1A2E),
      foregroundColor: Colors.white,
      title: Text('فاتورة $orderNumber',
        style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700)),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Color(0xFFB8963E)),
          onPressed: () => InvoiceService.instance.shareInvoice(order, context),
          tooltip: 'مشاركة',
        ),
        IconButton(
          icon: const Icon(Icons.print_outlined, color: Color(0xFFB8963E)),
          onPressed: () => Printing.layoutPdf(onLayout: (_) async => bytes),
          tooltip: 'طباعة',
        ),
      ],
    ),
    body: PdfPreview(
      build: (_) async => bytes,
      allowPrinting: false,
      allowSharing: false,
      canChangeOrientation: false,
      canChangePageFormat: false,
      pdfFileName: 'invoice_$orderNumber.pdf',
    ),
  );
}
