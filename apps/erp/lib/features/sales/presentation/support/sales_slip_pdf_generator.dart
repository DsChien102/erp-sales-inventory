import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/sales/data/models.dart';

import '../models/return_exchange_order/sales_return_exchange_detail_vm.dart';
import 'package:erp/core/formatting/money_formatter.dart';

enum SalesSlipType { sales, returnExchange }

/// Generates PDF document bytes for Return/Exchange slips from authoritative detail.
///
/// Sales receipt rendering moved to `SalesReceiptPdfGenerator`.
class SalesSlipPdfGenerator {
  static Future<Uint8List> generateReturnExchange({
    required SalesReturnExchangeDetailVm detail,
    required String orderNumber,
    required String customerDisplayName,
    String? storeName,
    String? storeCode,
    String? customerPhoneNumber,
  }) async {
    final fonts = await _loadFonts();
    final theme = pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold);
    final pdf = pw.Document();

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
          child: _buildReturnSlipBody(
            detail: detail,
            orderNumber: orderNumber,
            customerDisplayName: customerDisplayName,
            storeName: storeName,
            storeCode: storeCode,
            customerPhoneNumber: customerPhoneNumber,
            fonts: fonts,
          ),
        ),
      ),
    );

    return pdf.save();
  }

  /// Legacy entry — sales receipts are unsupported; return exchange requires
  /// [generateReturnExchange].
  static Future<Uint8List> generate({
    required SalesSlipType type,
    SalesReturnExchangeDetailVm? detail,
    String? orderNumber,
    String? customerDisplayName,
    String? storeName,
    String? storeCode,
    String? customerPhoneNumber,
  }) async {
    if (type == SalesSlipType.sales) {
      throw UnsupportedError(
        'SalesSlipPdfGenerator no longer supports sales receipts. '
        'Use SalesReceiptPdfGenerator instead.',
      );
    }
    final resolved = detail;
    if (resolved == null) {
      throw ArgumentError.value(
        detail,
        'detail',
        'Return-exchange PDF requires SalesReturnExchangeDetailVm.',
      );
    }
    return generateReturnExchange(
      detail: resolved,
      orderNumber: orderNumber ?? '',
      customerDisplayName: customerDisplayName ?? '',
      storeName: storeName,
      storeCode: storeCode,
      customerPhoneNumber: customerPhoneNumber,
    );
  }

  /// Settlement rows the return slip prints; the first row is the headline.
  ///
  /// Follows the slip template (collect / refund / zero difference). A refund
  /// on an order that still owes is split by the server into the cash refund
  /// and a reduction of this order's own debt, so the refund template gets one
  /// extra "Giảm nợ đơn" row. An offset into other orders (done by the server
  /// when confirming, TH-06 EP-03) prints one "Cấn trừ sang đơn khác" row.
  static List<(String, String)> settlementRows(ReturnExchangeSettlementPlanDto plan) {
    final netMinor = plan.netDifferenceMinor;
    if (netMinor > 0) {
      final processedCollect = plan.processedCollectMinor;
      final pendingReceivable = plan.receivableCreateAmountMinor > 0
          ? plan.receivableCreateAmountMinor
          : plan.pendingReceivableCreateMinor;
      final newlyIncurredDebt = pendingReceivable > 0
          ? pendingReceivable
          : (processedCollect < netMinor ? netMinor - processedCollect : 0);
      return [
        ('Phải thu thêm', MoneyFormatter.formatMinor(netMinor)),
        ('Đã thu', MoneyFormatter.formatMinor(processedCollect)),
        ('Công nợ phát sinh', MoneyFormatter.formatMinor(newlyIncurredDebt)),
      ];
    }
    if (netMinor < 0) {
      final debtReduction = plan.receivableReverseAmountMinor > 0
          ? plan.receivableReverseAmountMinor
          : plan.pendingReceivableReverseMinor;
      final refunded = plan.processedRefundMinor > 0
          ? plan.processedRefundMinor
          : plan.refundAmountMinor;
      return [
        // Headline is the real cash refund, not |net|: with order debt the
        // rest of |net| is the debt reduction below.
        ('Cần hoàn tiền', MoneyFormatter.formatMinor(plan.refundAmountMinor)),
        if (debtReduction > 0) ('Giảm nợ đơn', MoneyFormatter.formatMinor(debtReduction)),
        if (plan.offsetAmountMinor > 0)
          ('Cấn trừ sang đơn khác', MoneyFormatter.formatMinor(plan.offsetAmountMinor)),
        ('Đã hoàn', MoneyFormatter.formatMinor(refunded)),
      ];
    }
    return [('Không chênh lệch', MoneyFormatter.formatMinor(0))];
  }

  static String sanitizeFileName(String referenceNumber) {
    final sanitized = referenceNumber.replaceAll(RegExp(r'[^\w\-.]'), '_');
    final compacted = sanitized.replaceAll(RegExp(r'_+'), '_');
    return compacted.isEmpty ? 'return_exchange.pdf' : '$compacted.pdf';
  }

  static pw.Widget _buildReturnSlipBody({
    required SalesReturnExchangeDetailVm detail,
    required String orderNumber,
    required String customerDisplayName,
    String? storeName,
    String? storeCode,
    String? customerPhoneNumber,
    required _PdfFonts fonts,
  }) {
    final plan = detail.settlementPlan;
    final rows = settlementRows(plan);

    final returnItems = detail.lines
        .where((line) => line.kind == ReturnExchangeLineKind.returnLine)
        .toList(growable: false);
    final exchangeItems = detail.lines
        .where((line) => line.kind == ReturnExchangeLineKind.exchangeLine)
        .toList(growable: false);

    final confirmedAt = detail.confirmedAt ?? detail.completedAt ?? detail.createdAt;
    final orderNo = orderNumber.replaceAll('#', '');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _buildHeader(storeName: storeName, storeCode: storeCode, fonts: fonts),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'PHIẾU ĐỔI/TRẢ',
                style: pw.TextStyle(font: fonts.bold, fontSize: 16),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                '${detail.referenceNumber}  ·  Đơn $orderNo',
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
        _row(
          'Ngày xác nhận',
          confirmedAt == null ? '—' : _formatDateTime(confirmedAt),
          fonts,
        ),
        if (customerDisplayName.trim().isNotEmpty) ...[
          pw.SizedBox(height: 3),
          _row('Khách hàng', customerDisplayName, fonts),
          if (customerPhoneNumber != null && customerPhoneNumber.trim().isNotEmpty) ...[
            pw.SizedBox(height: 3),
            _row('Số điện thoại', customerPhoneNumber, fonts),
          ],
        ],
        pw.SizedBox(height: 6),
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.SizedBox(height: 6),
        pw.Text(
          'Hàng trả',
          style: pw.TextStyle(font: fonts.bold, fontSize: 11),
        ),
        pw.SizedBox(height: 6),
        if (returnItems.isEmpty)
          pw.Text(
            'Không có dòng trả',
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          )
        else
          for (var i = 0; i < returnItems.length; i++) ...[
            if (i > 0) pw.SizedBox(height: 4),
            _productRow(returnItems[i], fonts),
          ],
        if (exchangeItems.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(
            'Hàng đổi',
            style: pw.TextStyle(font: fonts.bold, fontSize: 11),
          ),
          pw.SizedBox(height: 6),
          for (var i = 0; i < exchangeItems.length; i++) ...[
            if (i > 0) pw.SizedBox(height: 4),
            _productRow(exchangeItems[i], fonts),
          ],
        ],
        pw.SizedBox(height: 6),
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.SizedBox(height: 6),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) pw.SizedBox(height: 3),
          _row(
            rows[i].$1,
            rows[i].$2,
            fonts,
            isBoldLabel: i == 0,
            isBoldValue: i == 0,
            valueColor: i == 0 ? PdfColor.fromHex('#1F7A36') : null,
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text(
            'Cảm ơn quý khách!',
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildHeader({
    String? storeName,
    String? storeCode,
    required _PdfFonts fonts,
  }) {
    final resolvedStoreName = storeName?.trim().isNotEmpty == true
        ? storeName!.trim().toUpperCase()
        : 'CỬA HÀNG';
    final resolvedStoreCode = storeCode?.trim() ?? '';

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
                    resolvedStoreName,
                    style: pw.TextStyle(font: fonts.bold, fontSize: 12),
                    textAlign: pw.TextAlign.right,
                  ),
                  if (resolvedStoreCode.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      resolvedStoreCode,
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

  static pw.Widget _row(
    String label,
    String value,
    _PdfFonts fonts, {
    bool isBoldLabel = false,
    bool isBoldValue = false,
    PdfColor? valueColor,
  }) {
    final isValueNumber = RegExp(r'[0-9]').hasMatch(value);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: isBoldLabel ? fonts.bold : fonts.regular,
            fontSize: 10.5,
            color: isBoldLabel ? PdfColors.black : PdfColors.grey800,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: isValueNumber
                ? (isBoldValue ? fonts.monoBold : fonts.mono)
                : (isBoldValue ? fonts.bold : fonts.regular),
            fontSize: 10.5,
            color: valueColor ?? (isBoldValue ? PdfColors.black : PdfColors.grey900),
          ),
        ),
      ],
    );
  }

  static pw.Widget _productRow(
    ReturnExchangeDetailLineDto item,
    _PdfFonts fonts,
  ) {
    final qty = _formatQuantity(item.quantity);
    final unit = item.unit.unitName;
    final amountText = MoneyFormatter.formatMinor(item.lineTotal.amountMinor);
    final priceText = MoneyFormatter.formatMinor(item.unitPrice.amountMinor);
    final qtyMicros = item.quantity.quantityMicros;
    final qtyValue = qtyMicros / QuantityDto.scale;
    final isDiscounted =
        qtyValue > 0 &&
        item.lineTotal.amountMinor < (item.unitPrice.amountMinor * qtyValue).round();
    final actualUnitPriceMinor = qtyValue > 0
        ? (item.lineTotal.amountMinor / qtyValue).round()
        : item.unitPrice.amountMinor;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                item.product.displayName,
                style: pw.TextStyle(font: fonts.bold, fontSize: 10.5),
              ),
              pw.SizedBox(height: 2),
              if (isDiscounted)
                pw.Row(
                  children: [
                    pw.Text(
                      '$qty $unit × ',
                      style: pw.TextStyle(
                        font: fonts.mono,
                        fontSize: 9.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      priceText,
                      style: pw.TextStyle(
                        font: fonts.mono,
                        fontSize: 9.5,
                        color: PdfColors.grey500,
                        decoration: pw.TextDecoration.lineThrough,
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      MoneyFormatter.formatMinor(actualUnitPriceMinor),
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
                  '$qty $unit × $priceText',
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
          amountText,
          style: pw.TextStyle(font: fonts.monoBold, fontSize: 10.5),
        ),
      ],
    );
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
