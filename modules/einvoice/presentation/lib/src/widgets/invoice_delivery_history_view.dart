import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

import '../support/send_invoice_copy.dart';

/// One delivery attempt shown on [InvoiceDeliveryHistoryView].
class InvoiceDeliveryHistoryRowData {
  const InvoiceDeliveryHistoryRowData({
    required this.success,
    required this.email,
    required this.date,
    required this.time,
    required this.actor,
    this.deliveryStatus,
  });

  factory InvoiceDeliveryHistoryRowData.fromDelivery(
    InvoiceDeliveryItemDto delivery, {
    required String actor,
  }) {
    final date = (delivery.completedAt ?? delivery.startedAt).toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return InvoiceDeliveryHistoryRowData(
      success: delivery.status == DeliveryStatus.succeeded,
      email: delivery.recipientEmail,
      date: '${two(date.day)}/${two(date.month)}/${date.year}',
      time: '${two(date.hour)}:${two(date.minute)}',
      actor: actor,
      deliveryStatus: delivery.status,
    );
  }

  final DeliveryStatus? deliveryStatus;
  final bool success;
  final String email;
  final String date;
  final String time;
  final String actor;
}

/// Summary for the invoice header card on delivery history.
class InvoiceDeliveryHistorySummary {
  const InvoiceDeliveryHistorySummary({
    required this.invoiceNumber,
    required this.templateNumber,
    required this.invoiceSymbol,
    required this.issuedTime,
    required this.issuedDate,
  });

  final String invoiceNumber;
  final String templateNumber;
  final String invoiceSymbol;
  final String issuedTime;
  final String issuedDate;

  /// Preview fixture from approved design (not a business constant).
  static const preview = InvoiceDeliveryHistorySummary(
    invoiceNumber: '0000129',
    templateNumber: '1/001',
    invoiceSymbol: 'C26TAA',
    issuedTime: '09:41',
    issuedDate: '22/07/2026',
  );
}

/// Scrollable body for SG07-D01 delivery history.
class InvoiceDeliveryHistoryView extends StatelessWidget {
  const InvoiceDeliveryHistoryView({
    super.key,
    required this.summary,
    required this.rows,
  });

  final InvoiceDeliveryHistorySummary summary;
  final List<InvoiceDeliveryHistoryRowData> rows;

  /// Preview fixture matching approved board (newest first).
  static const previewRows = <InvoiceDeliveryHistoryRowData>[
    InvoiceDeliveryHistoryRowData(
      success: true,
      email: 'accounting@company.com',
      date: '05/08/2026',
      time: '16:20',
      actor: 'Nguyễn Văn An',
    ),
    InvoiceDeliveryHistoryRowData(
      success: false,
      email: 'accounting@company.com',
      date: '05/08/2026',
      time: '16:16',
      actor: 'Nguyễn Văn An',
    ),
    InvoiceDeliveryHistoryRowData(
      success: true,
      email: 'customer@company.com',
      date: '05/08/2026',
      time: '16:12',
      actor: SendInvoiceCopy.actorAutomatic,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return ListView(
      padding: const EdgeInsets.all(VSpacing.space4),
      children: [
        VCard(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: VText(
                      SendInvoiceCopy.invoiceSummaryTitle(summary.invoiceNumber),
                      variant: VTextVariant.headingH4,
                      color: colors.textPrimary,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const VBadge(
                    label: SendInvoiceCopy.issuedBadge,
                    status: VBadgeStatus.success,
                    isSmall: true,
                  ),
                ],
              ),
              const VGap.sm(),
              VText(
                SendInvoiceCopy.invoiceMetadata(
                  templateNumber: summary.templateNumber,
                  invoiceSymbol: summary.invoiceSymbol,
                ),
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
              const VGap.xs(),
              VText(
                SendInvoiceCopy.issuedAt(
                  issuedTime: summary.issuedTime,
                  issuedDate: summary.issuedDate,
                ),
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
        const VGap.lg(),
        VText(
          SendInvoiceCopy.historySectionTitle,
          variant: VTextVariant.headingH4,
          color: colors.textPrimary,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const VGap.md(),
        VCard(
          padding: const EdgeInsets.symmetric(vertical: VSpacing.space2),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.borderDefault),
                _DeliveryHistoryRow(data: rows[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DeliveryHistoryRow extends StatelessWidget {
  const _DeliveryHistoryRow({required this.data});

  final InvoiceDeliveryHistoryRowData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final icon = data.success ? VIcons.success : VIcons.error;
    final iconColor = data.success ? colors.success : colors.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VIcon(icon: icon, color: iconColor, size: 20),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  data.deliveryStatus == DeliveryStatus.processing
                      ? 'Đang gửi · ${data.email}'
                      : data.deliveryStatus == DeliveryStatus.unknown
                      ? 'Không xác định kết quả · ${data.email}'
                      : SendInvoiceCopy.deliveryMainText(
                          success: data.success,
                          email: data.email,
                        ),
                  variant: VTextVariant.bodyDefault,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const VGap.xs(),
                VText(
                  SendInvoiceCopy.deliveryMetadata(
                    date: data.date,
                    time: data.time,
                    actor: data.actor,
                  ),
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
