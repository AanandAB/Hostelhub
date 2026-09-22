import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/inmate.dart';
import '../../data/models/property.dart';
import '../../presentation/widgets/glass.dart';
import '../onboarding/hostel_providers.dart';

/// Owner generates a bill / invoice: single (whole property) or split (per
/// inmate), exported as a shareable PDF.
class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  bool _split = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final propAsync = ref.watch(currentPropertyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills & invoices'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        dark: isDark,
        child: SafeArea(
          child: propAsync.when(
            data: (prop) => prop == null
                ? Center(
                    child: Text('Set up your property first.',
                        style: textTheme.bodyMedium))
                : _content(context, ref, prop, textTheme),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(child: Text('Error')),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, Property prop,
      TextTheme textTheme) {
    final inmates =
        ref.watch(inmatesProvider(prop.id)).value ?? const <Inmate>[];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final mess = (prop.messCharges['monthly'] as num?)?.toInt() ?? 0;

    final rows = <(String, int)>[
      for (final i in inmates)
        (i.name, i.rentAmount + (prop.featureEnabled('mess') ? mess : 0)),
    ];
    final total = rows.fold<int>(0, (s, r) => s + r.$2);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prop.name, style: textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Bill for ${DateTime.now().toIso8601String().substring(0, 10)}',
                  style: textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Row(
            children: [
              const Icon(Icons.call_split_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Split bill', style: textTheme.titleMedium),
                    Text('Separate bill per inmate (e.g. house residents)',
                        style: textTheme.bodySmall),
                  ],
                ),
              ),
              Switch(value: _split, onChanged: (v) => setState(() => _split = v)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          Center(child: Text('No inmates to bill.', style: textTheme.bodyMedium))
        else if (_split)
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(child: Text(r.$1, style: textTheme.bodyLarge)),
                    Text('₹${r.$2}', style: textTheme.titleMedium),
                  ],
                ),
              ),
            )
        else
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text('${rows.length} inmate(s) — single bill',
                      style: textTheme.bodyMedium),
                ),
                Text('₹$total', style: textTheme.titleLarge),
              ],
            ),
          ),
        const SizedBox(height: 20),
        GlassButton(
          label: 'Generate & share PDF',
          icon: Icons.picture_as_pdf_rounded,
          loading: _busy,
          onPressed: rows.isEmpty
              ? null
              : () => _sharePdf(prop, rows, total, primary),
        ),
      ],
    );
  }

  Future<void> _sharePdf(Property prop, List<(String, int)> rows, int total,
      Color primary) async {
    setState(() => _busy = true);
    try {
      final doc = pw.Document();
      final now = DateTime.now().toIso8601String().substring(0, 10);
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => [
            pw.Text('HostelHub — Bill / Invoice',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(prop.name),
            pw.Text('Date: $now'),
            pw.Divider(),
            pw.SizedBox(height: 8),
            if (_split)
              for (final r in rows)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(r.$1),
                      pw.Text('Rs. ${r.$2}'),
                    ],
                  ),
                )
            else ...[
              pw.Text('Single bill — ${rows.length} inmate(s)'),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs. $total',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
            pw.Divider(),
            pw.SizedBox(height: 4),
            pw.Text('Generated by HostelHub', style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      );
      await Printing.sharePdf(
          bytes: await doc.save(), filename: 'hostelhub-bill-$now.pdf');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
