import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/sales/data/models.dart';

import 'package:erp/core/formatting/money_formatter.dart';

final class SalesReceiptPdfGenerator {
  /// Label/value rows the PDF prints for the commercial and settlement totals.
  static List<(String, String)> summaryRows(SalesReceiptDocumentDto document) {
    return [
      ('Tiền hàng', _money(document.subtotal)),
      ('Giảm giá', _money(document.discountTotal)),
      ('Tổng đơn', _money(_orderTotal(document))),
      ('Còn phải thu', _money(_outstanding(document))),
    ];
  }

  /// Lines already reflect returns/exchanges, so the total is the current
  /// payable (older receipts stored the original total in `orderTotal`).
  static MoneyDto _orderTotal(SalesReceiptDocumentDto document) =>
      document.settlementSnapshot?.currentPayable ?? document.orderTotal;

  static MoneyDto _outstanding(SalesReceiptDocumentDto document) =>
      document.settlementSnapshot?.outstanding ?? document.outstandingTotal;

  static String _money(MoneyDto money) =>
      MoneyFormatter.format(amountMinor: money.amountMinor, currencyCode: money.currencyCode);

  static Future<Uint8List> generate(SalesReceiptDocumentDto document) async {
    final pdf = pw.Document();
    final fonts = await _loadFonts();
    final theme = pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        theme: theme,
        margin: const pw.EdgeInsets.all(10),
        build: (_) => pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(16),
          ),
          child: _buildBody(document, fonts),
        ),
      ),
    );

    return pdf.save();
  }

  static String sanitizeFileName(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^\w\-.]'), '_');
    final compacted = sanitized.replaceAll(RegExp(r'_+'), '_');
    return compacted.isEmpty ? 'sales_receipt.pdf' : '$compacted.pdf';
  }

  static pw.Widget _buildBody(SalesReceiptDocumentDto document, _PdfFonts fonts) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _buildHeader(document, fonts),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'PHIẾU BÁN HÀNG',
                style: pw.TextStyle(font: fonts.bold, fontSize: 16),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                '${document.receiptNumber}  ·  Đơn ${document.orderNumber}',
                style: pw.TextStyle(
                  font: fonts.mono,
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        _row('Ngày bán', _formatDateTime(document.soldAt), fonts),
        if (document.customer != null) ...[
          pw.SizedBox(height: 3),
          _row('Khách hàng', document.customer!.displayName, fonts),
          if ((document.customer!.phoneNumber ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 3),
            _row('Số điện thoại', document.customer!.phoneNumber!, fonts),
          ],
        ],
        pw.SizedBox(height: 6),
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.SizedBox(height: 6),
        for (var i = 0; i < document.lines.length; i++) ...[
          if (i > 0) pw.SizedBox(height: 6),
          _line(document.lines[i], fonts),
        ],
        pw.SizedBox(height: 6),
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.SizedBox(height: 6),
        _row(
          'Tiền hàng',
          MoneyFormatter.format(
            amountMinor: document.subtotal.amountMinor,
            currencyCode: document.subtotal.currencyCode,
          ),
          fonts,
        ),
        pw.SizedBox(height: 3),
        _row(
          'Giảm giá',
          MoneyFormatter.format(
            amountMinor: document.discountTotal.amountMinor,
            currencyCode: document.discountTotal.currencyCode,
          ),
          fonts,
        ),
        pw.SizedBox(height: 5),
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#E8F6EC'),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Tổng đơn',
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: 11,
                  color: PdfColors.black,
                ),
              ),
              pw.Text(
                _money(_orderTotal(document)),
                style: pw.TextStyle(
                  font: fonts.monoBold,
                  fontSize: 11,
                  color: PdfColor.fromHex('#1F7A36'),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
        if (document.payments.isNotEmpty) ...[
          for (final payment in document.payments) ...[
            _row(
              _paymentLabel(payment.method),
              MoneyFormatter.format(
                amountMinor: payment.amount.amountMinor,
                currencyCode: payment.amount.currencyCode,
              ),
              fonts,
            ),
            pw.SizedBox(height: 3),
          ],
        ] else if (document.paidTotal.amountMinor > 0) ...[
          _row(
            'Đã thanh toán',
            MoneyFormatter.format(
              amountMinor: document.paidTotal.amountMinor,
              currencyCode: document.paidTotal.currencyCode,
            ),
            fonts,
          ),
          pw.SizedBox(height: 3),
        ],
        _row(
          'Còn phải thu',
          _money(_outstanding(document)),
          fonts,
          boldLabel: true,
          boldValue: true,
        ),
        if (document.dueAt != null) ...[
          pw.SizedBox(height: 3),
          _row('Hạn thu', _formatDate(document.dueAt!), fonts),
        ],
        if (document.customer != null) ...[
          pw.SizedBox(height: 6),
          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          pw.SizedBox(height: 6),
          _buildDebtSection(document, fonts),
        ],
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text(
            'Cám ơn quý khách!',
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 10,
              color: PdfColors.grey600,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Center(
          child: pw.Text(
            'Phiếu bán hàng nội bộ — không phải hóa đơn điện tử',
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 8.5,
              color: PdfColors.grey500,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildHeader(SalesReceiptDocumentDto document, _PdfFonts fonts) {
    final storeName = document.store.displayName.toUpperCase();
    final storeCode = document.store.storeCode.trim();
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 44,
              height: 44,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#1F7A36'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'V45',
                style: pw.TextStyle(
                  font: fonts.bold,
                  color: PdfColors.white,
                  fontSize: 18,
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    storeName,
                    style: pw.TextStyle(font: fonts.bold, fontSize: 12),
                    textAlign: pw.TextAlign.right,
                  ),
                  if (storeCode.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      storeCode,
                      style: pw.TextStyle(
                        font: fonts.regular,
                        color: PdfColors.grey700,
                        fontSize: 10,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
      ],
    );
  }

  static pw.Widget _buildDebtSection(SalesReceiptDocumentDto document, _PdfFonts fonts) {
    final newDebt = document.outstandingTotal.amountMinor;

    return pw.Column(
      children: [
        _row(
          'Công nợ phát sinh từ đơn',
          MoneyFormatter.formatMinor(newDebt),
          fonts,
        ),
      ],
    );
  }

  static pw.Widget _row(
    String label,
    String value,
    _PdfFonts fonts, {
    bool boldLabel = false,
    bool boldValue = false,
    PdfColor? valueColor,
  }) {
    final isNumeric = RegExp(r'[0-9]').hasMatch(value);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: boldLabel ? fonts.bold : fonts.regular,
            fontSize: 10.5,
            color: boldLabel ? PdfColors.black : PdfColors.grey800,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: isNumeric
                ? (boldValue ? fonts.monoBold : fonts.mono)
                : (boldValue ? fonts.bold : fonts.regular),
            fontSize: 10.5,
            color: valueColor ?? (boldValue ? PdfColors.black : PdfColors.grey900),
          ),
        ),
      ],
    );
  }

  static pw.Widget _line(SalesReceiptLineDto line, _PdfFonts fonts) {
    final quantityText = _formatQuantity(line.quantity);
    final unitLabel = line.unit.unitName;
    final unitPriceText = MoneyFormatter.format(
      amountMinor: line.unitPrice.amountMinor,
      currencyCode: line.unitPrice.currencyCode,
    );
    final hasDiscount = line.discountTotal.amountMinor > 0;
    final qtyMicros = line.quantity.quantityMicros;
    final qtyValue = qtyMicros / QuantityDto.scale;
    final discountedUnitPriceMinor = qtyValue > 0
        ? (line.lineTotal.amountMinor / qtyValue).round()
        : line.unitPrice.amountMinor;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                line.product.displayName,
                style: pw.TextStyle(font: fonts.bold, fontSize: 10.5),
              ),
              pw.SizedBox(height: 2),
              if (hasDiscount)
                pw.Row(
                  children: [
                    pw.Text(
                      '$quantityText $unitLabel × ',
                      style: pw.TextStyle(
                        font: fonts.mono,
                        fontSize: 9.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      unitPriceText,
                      style: pw.TextStyle(
                        font: fonts.mono,
                        fontSize: 9.5,
                        color: PdfColors.grey500,
                        decoration: pw.TextDecoration.lineThrough,
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      MoneyFormatter.formatMinor(discountedUnitPriceMinor),
                      style: pw.TextStyle(
                        font: fonts.monoBold,
                        fontSize: 9.5,
                        color: PdfColors.grey900,
                      ),
                    ),
                  ],
                )
              else
                pw.Text(
                  '$quantityText $unitLabel × $unitPriceText',
                  style: pw.TextStyle(
                    font: fonts.mono,
                    fontSize: 9.5,
                    color: PdfColors.grey700,
                  ),
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Text(
          MoneyFormatter.format(
            amountMinor: line.lineTotal.amountMinor,
            currencyCode: line.lineTotal.currencyCode,
          ),
          style: pw.TextStyle(font: fonts.monoBold, fontSize: 10.5),
        ),
      ],
    );
  }

  static String _paymentLabel(SalesPaymentMethod method) {
    return switch (method) {
      SalesPaymentMethod.cash => 'Tiền mặt',
      SalesPaymentMethod.manualBankTransfer => 'Chuyển khoản',
      SalesPaymentMethod.offset => 'Cấn trừ',
    };
  }

  static String _formatQuantity(QuantityDto quantity) {
    final value = quantity.quantityMicros / QuantityDto.scale;
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String _formatDateTime(DateTime value) => VDateTime.dateTime(value);

  static String _formatDate(DateTime value) => VDateTime.calendarDate(value);

  static Future<_PdfFonts> _loadFonts() async {
    try {
      final regular = await rootBundle.load(
        'packages/c45_design_system/assets/fonts/ttf_Inter/Inter-Regular.ttf',
      );
      final bold = await rootBundle.load(
        'packages/c45_design_system/assets/fonts/ttf_Inter/Inter-Bold.ttf',
      );
      final mono = await rootBundle.load(
        'packages/c45_design_system/assets/fonts/ttf_JetBrainsMono/JetBrainsMono-Regular.ttf',
      );
      final monoBold = await rootBundle.load(
        'packages/c45_design_system/assets/fonts/ttf_JetBrainsMono/JetBrainsMono-Bold.ttf',
      );
      return _PdfFonts(
        regular: pw.Font.ttf(regular),
        bold: pw.Font.ttf(bold),
        mono: pw.Font.ttf(mono),
        monoBold: pw.Font.ttf(monoBold),
      );
    } catch (_) {
      try {
        return _PdfFonts(
          regular: await PdfGoogleFonts.robotoRegular(),
          bold: await PdfGoogleFonts.robotoBold(),
          mono: await PdfGoogleFonts.robotoMonoRegular(),
          monoBold: await PdfGoogleFonts.robotoMonoBold(),
        );
      } catch (_) {
        return _PdfFonts(
          regular: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
          mono: pw.Font.courier(),
          monoBold: pw.Font.courierBold(),
        );
      }
    }
  }
}

final class _PdfFonts {
  const _PdfFonts({
    required this.regular,
    required this.bold,
    required this.mono,
    required this.monoBold,
  });

  final pw.Font regular;
  final pw.Font bold;
  final pw.Font mono;
  final pw.Font monoBold;
}
