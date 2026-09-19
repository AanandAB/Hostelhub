import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Indian-style number formatting: 15000 → "15,000", 150000 → "1,50,000".
String inrFormat(int n) {
  final s = n.toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}

/// Builds a standard, well-structured per-inmate invoice PDF from the invoice
/// JSON the backend returns (GET /inmates/:id/invoice). Uses "Rs." in the PDF
/// (the built-in PDF fonts don't carry the ₹ glyph); the on-screen UI shows ₹.
pw.Document buildInvoicePdf(Map<String, dynamic> inv) {
  final p = inv['property'] as Map<String, dynamic>? ?? const {};
  final i = inv['inmate'] as Map<String, dynamic>? ?? const {};
  final lineItems = (inv['line_items'] as List? ?? const [])
      .cast<Map<String, dynamic>>();
  final roomNo = (i['room_no'] ?? '').toString();
  final bedNo = (i['bed_no'] ?? 0).toString();
  final total = (inv['total'] as num?)?.toInt() ?? 0;
  final depositHeld = (inv['deposit_held'] as num?)?.toInt() ?? 0;

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('TAX INVOICE',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text('${p['name'] ?? ''}',
              style: const pw.TextStyle(fontSize: 13)),
          if ((p['address'] ?? '').toString().isNotEmpty)
            pw.Text('${p['address']}', style: const pw.TextStyle(fontSize: 10)),
          pw.Divider(),
        ],
      ),
      build: (ctx) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Billed to',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey700)),
                pw.Text('${i['name'] ?? ''}',
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold)),
                if (roomNo.isNotEmpty)
                  pw.Text('Room $roomNo · Bed $bedNo',
                      style: const pw.TextStyle(fontSize: 10)),
                if ((i['email'] ?? '').toString().isNotEmpty)
                  pw.Text('${i['email']}', style: const pw.TextStyle(fontSize: 10)),
                if ((i['phone'] ?? '').toString().isNotEmpty)
                  pw.Text('${i['phone']}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Invoice #: ${inv['invoice_no']}',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text('Date: ${inv['invoice_date']}',
                    style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Due: ${inv['due_date']}',
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 24),
        pw.TableHelper.fromTextArray(
          headers: ['Description', 'Amount'],
          data: [
            for (final li in lineItems)
              [
                '${li['description'] ?? ''}',
                'Rs. ${inrFormat((li['amount'] as num?)?.toInt() ?? 0)}',
              ],
          ],
          headerStyle:
              pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          cellStyle: const pw.TextStyle(fontSize: 11),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignments: {1: pw.Alignment.centerRight},
          columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1)},
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Total due',
                    style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Rs. ${inrFormat(total)}',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 28),
        pw.Text('Security deposit held: Rs. ${inrFormat(depositHeld)}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(
            'Payment is due by ${inv['due_date']}. Please pay on time — thank you.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ],
    ),
  );
  return doc;
}
