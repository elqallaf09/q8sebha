import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';

class InvoiceService {
  static InvoiceService get instance => _i;
  static final _i = InvoiceService._();
  InvoiceService._();

  // ─── ألوان الفاتورة ────────────────────────────────────────────────────────
  static const _gold    = PdfColor.fromInt(0xFFB8963E);
  static const _dark    = PdfColor.fromInt(0xFF1A1A2E);
  static const _bg      = PdfColor.fromInt(0xFFF8F5EE);
  static const _white   = PdfColors.white;
  static const _grey    = PdfColor.fromInt(0xFF8E8E93);
  static const _border  = PdfColor.fromInt(0xFFE8E0D0);

  // ─── توليد PDF ─────────────────────────────────────────────────────────────
  Future<File> generate(Order order, {String? storeName}) async {
    final pdf = pw.Document();
    final font     = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    final store = storeName ?? 'مسابيح لايقر';

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (ctx) => pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Column(children: [
          // ── هيدر ──────────────────────────────────────────────────────────
          _header(store, font, fontBold),
          // ── معلومات الفاتورة ──────────────────────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // العميل
                _infoBox('معلومات العميل', [
                  order.buyerName ?? 'عميل',
                  order.buyerPhone ?? '',
                  if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty)
                    order.deliveryAddress!,
                ], font, fontBold),
                // الفاتورة
                _infoBox('معلومات الفاتورة', [
                  'رقم: ${order.orderNumber}',
                  'التاريخ: $dateStr',
                  'الحالة: ${order.statusDisplay}',
                ], font, fontBold),
              ],
            ),
          ),
          // ── جدول المنتجات ─────────────────────────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 32),
            child: _itemsTable(order, font, fontBold),
          ),
          pw.SizedBox(height: 16),
          // ── الإجمالي ──────────────────────────────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 32),
            child: _totalsSection(order, font, fontBold),
          ),
          // ── ملاحظات ───────────────────────────────────────────────────────
          if (order.notes != null && order.notes!.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(32, 16, 32, 0),
              child: _notesBox(order.notes!, font),
            ),
          pw.Spacer(),
          // ── فوتر ──────────────────────────────────────────────────────────
          _footer(store, font),
        ]),
      ),
    ));

    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_${order.orderNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ─── هيدر الفاتورة ────────────────────────────────────────────────────────
  pw.Widget _header(String store, pw.Font font, pw.Font bold) =>
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const pw.BoxDecoration(color: _dark),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // يسار — اسم المتجر
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('INVOICE / فاتورة',
              style: pw.TextStyle(font: font, color: _gold, fontSize: 11)),
            pw.SizedBox(height: 4),
            pw.Text(store,
              style: pw.TextStyle(font: bold, color: _white, fontSize: 22)),
          ]),
          // يمين — أيقونة تزيينية
          pw.Container(
            width: 60, height: 60,
            decoration: pw.BoxDecoration(
              color: _gold,
              borderRadius: pw.BorderRadius.circular(12)),
            child: pw.Center(
              child: pw.Text('📿',
                style: pw.TextStyle(font: font, fontSize: 28)))),
        ],
      ),
    );

  // ─── صندوق المعلومات ───────────────────────────────────────────────────────
  pw.Widget _infoBox(String title, List<String> lines, pw.Font font, pw.Font bold) =>
    pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _bg,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _border, width: 0.5)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Text(title,
          style: pw.TextStyle(font: bold, fontSize: 10, color: _gold)),
        pw.Divider(color: _border, height: 8),
        ...lines.where((l) => l.isNotEmpty).map((l) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Text(l,
            style: pw.TextStyle(font: font, fontSize: 10, color: _dark)))),
      ]),
    );

  // ─── جدول المنتجات ────────────────────────────────────────────────────────
  pw.Widget _itemsTable(Order order, pw.Font font, pw.Font bold) {
    final headers = ['الإجمالي', 'السعر', 'الكمية', 'المنتج'];
    final rows = order.isCartOrder && order.items.isNotEmpty
        ? order.items.map((item) => [
            '${item.totalPrice.toStringAsFixed(3)} د.ك',
            '${item.unitPrice.toStringAsFixed(3)} د.ك',
            '${item.quantity}',
            '${item.productEmoji} ${item.productName}',
          ]).toList()
        : [[
            '${order.totalPrice.toStringAsFixed(3)} د.ك',
            '${order.totalPrice.toStringAsFixed(3)} د.ك',
            '1',
            '${order.productEmoji ?? '📿'} ${order.productName ?? 'منتج'}',
          ]];

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(4),
      },
      children: [
        // هيدر الجدول
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _dark),
          children: headers.map((h) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: pw.Text(h,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(font: bold, fontSize: 10, color: _white)),
          )).toList(),
        ),
        // صفوف البيانات
        ...rows.asMap().entries.map((e) => pw.TableRow(
          decoration: pw.BoxDecoration(
            color: e.key % 2 == 0 ? _white : _bg),
          children: e.value.map((cell) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: pw.Text(cell,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(font: font, fontSize: 10, color: _dark)),
          )).toList(),
        )),
      ],
    );
  }

  // ─── قسم الإجمالي ─────────────────────────────────────────────────────────
  pw.Widget _totalsSection(Order order, pw.Font font, pw.Font bold) =>
    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
      pw.Container(
        width: 220,
        decoration: pw.BoxDecoration(
          color: _bg,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: _border, width: 0.5)),
        child: pw.Column(children: [
          // المجموع الفرعي
          if (order.isCartOrder && order.items.isNotEmpty)
            _totalRow('المجموع الفرعي',
              '${order.totalPrice.toStringAsFixed(3)} د.ك', font, false),
          pw.Divider(color: _border, height: 1),
          // الإجمالي الكلي
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const pw.BoxDecoration(color: _dark),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('${order.totalPrice.toStringAsFixed(3)} د.ك',
                  style: pw.TextStyle(font: bold, fontSize: 14, color: _gold)),
                pw.Text('الإجمالي الكلي',
                  style: pw.TextStyle(font: bold, fontSize: 11, color: _white)),
              ],
            ),
          ),
        ]),
      ),
    ]);

  pw.Widget _totalRow(String label, String value, pw.Font font, bool isTotal) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(value,
            style: pw.TextStyle(
              font: font, fontSize: isTotal ? 13 : 10,
              color: isTotal ? _gold : _dark)),
          pw.Text(label,
            style: pw.TextStyle(
              font: font, fontSize: isTotal ? 13 : 10,
              color: isTotal ? _dark : _grey)),
        ],
      ),
    );

  // ─── ملاحظات ──────────────────────────────────────────────────────────────
  pw.Widget _notesBox(String notes, pw.Font font) =>
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _gold, width: 0.8),
        borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Text('ملاحظات', style: pw.TextStyle(font: font, fontSize: 9, color: _gold)),
        pw.SizedBox(height: 4),
        pw.Text(notes, style: pw.TextStyle(font: font, fontSize: 10, color: _dark)),
      ]),
    );

  // ─── فوتر ─────────────────────────────────────────────────────────────────
  pw.Widget _footer(String store, pw.Font font) =>
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _gold, width: 1))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('شكراً لتسوقكم معنا 🙏',
            style: pw.TextStyle(font: font, fontSize: 9, color: _grey)),
          pw.Text(store,
            style: pw.TextStyle(font: font, fontSize: 9, color: _dark)),
        ],
      ),
    );

  // ─── مشاركة الفاتورة ─────────────────────────────────────────────────────
  Future<void> shareInvoice(Order order, BuildContext context) async {
    try {
      final file = await generate(order);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'فاتورة ${order.orderNumber} — مسابيح لايقر',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل إنشاء الفاتورة: $e',
            style: const TextStyle(fontFamily: 'Tajawal')),
          backgroundColor: Colors.red));
      }
    }
  }

  // ─── معاينة الفاتورة داخل التطبيق ────────────────────────────────────────
  Future<void> previewInvoice(Order order, BuildContext context) async {
    try {
      final bytes = await _buildBytes(order);
      if (!context.mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => _InvoicePreviewScreen(
          orderNumber: order.orderNumber,
          pdfBytes: bytes,
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

  Future<List<int>> _buildBytes(Order order) async {
    final file = await generate(order);
    return file.readAsBytes();
  }
}

// ─── شاشة معاينة الفاتورة ────────────────────────────────────────────────
class _InvoicePreviewScreen extends StatelessWidget {
  final String orderNumber;
  final List<int> pdfBytes;
  final Order order;
  const _InvoicePreviewScreen({
    required this.orderNumber,
    required this.pdfBytes,
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
        ),
        IconButton(
          icon: const Icon(Icons.print_outlined, color: Color(0xFFB8963E)),
          onPressed: () => Printing.layoutPdf(onLayout: (_) async => pdfBytes),
        ),
      ],
    ),
    body: PdfPreview(
      build: (_) async => pdfBytes,
      allowPrinting: false,
      allowSharing: false,
      canChangeOrientation: false,
      canChangePageFormat: false,
      pdfFileName: 'invoice_$orderNumber.pdf',
    ),
  );
}
