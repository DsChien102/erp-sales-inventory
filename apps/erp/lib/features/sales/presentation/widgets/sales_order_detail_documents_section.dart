import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'package:erp/features/sales/logic/sales_order_detail_state.dart';
import '../models/sales_order/sales_order_detail_vm.dart';
import 'sales_einvoice_entry_card.dart';
import 'sales_order_detail_history_entry.dart';
import 'sales_order_detail_returns_section.dart';
import 'sales_receipt_entry_card.dart';

/// "Chứng từ & hóa đơn" hub: receipt, e-invoice, optional returns + history
/// entries in one grouped surface (Figma D-01 / D-04 / D-06 variant A).
class SalesOrderDetailDocumentsSection extends StatelessWidget {
  const SalesOrderDetailDocumentsSection({
    super.key,
    required this.isCancelled,
    required this.eInvoiceStatus,
    required this.historyStatus,
    required this.returnSlips,
    required this.onOpenReceipt,
    this.onOpenEInvoice,
    this.eInvoiceSection,
    required this.onOpenReturnList,
    required this.onOpenHistory,
    required this.onRetryHistory,
    this.historyErrorMessage,
    this.showHistory = true,
  });

  final bool isCancelled;
  final SalesEInvoiceStatus eInvoiceStatus;
  final SalesOrderDetailSectionStatus historyStatus;
  final List<SalesReturnExchangeSlipItemVm> returnSlips;
  final String? historyErrorMessage;
  final VoidCallback onOpenReceipt;
  final VoidCallback? onOpenEInvoice;
  final Widget? eInvoiceSection;
  final VoidCallback onOpenReturnList;
  final VoidCallback onOpenHistory;
  final VoidCallback onRetryHistory;
  final bool showHistory;

  bool get _showReturnsRow =>
      (returnSlips.isNotEmpty || isCancelled) &&
      historyStatus != SalesOrderDetailSectionStatus.idle &&
      (historyStatus != SalesOrderDetailSectionStatus.loaded || returnSlips.isNotEmpty);

  bool get _showHistoryRow => showHistory || isCancelled;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (!isCancelled) ...[
        SalesReceiptEntryCard(
          key: const Key('btn_sg08_receipt'),
          onTap: onOpenReceipt,
        ),
        if (eInvoiceSection != null)
          eInvoiceSection!
        else
          SalesEInvoiceEntryCard(
            key: const Key('btn_sg08_einvoice'),
            subtitle: 'Quản lý HĐĐT',
            badgeLabel: _eInvoiceLabel(eInvoiceStatus),
            onTap: onOpenEInvoice,
          ),
      ],
      ?_buildReturnsRow(),
      ?_buildHistoryRow(),
    ];

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const VText(
          'Chứng từ & hóa đơn',
          variant: VTextVariant.bodyDefault,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const VGap.sm(),
        Column(
          key: const Key('wgt_sg08_documents_grouped'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const VGap.sm(),
              children[i],
            ],
          ],
        ),
      ],
    );
  }

  Widget? _buildReturnsRow() {
    if (!_showReturnsRow) {
      return null;
    }

    return SalesOrderDetailReturnsSection(
      slips: returnSlips,
      status: historyStatus,
      onTap: onOpenReturnList,
      onRetry: onRetryHistory,
    );
  }

  Widget? _buildHistoryRow() {
    if (!_showHistoryRow) {
      return null;
    }

    return SalesOrderDetailHistoryEntry(
      status: historyStatus,
      errorMessage: historyErrorMessage,
      subtitle: 'Thanh toán, chứng từ và nghiệp vụ sau bán',
      showEntryOnIdle: true,
      onTap: onOpenHistory,
      onRetry: onRetryHistory,
    );
  }

  static String _eInvoiceLabel(SalesEInvoiceStatus status) => switch (status) {
    SalesEInvoiceStatus.notIssued => 'Chưa phát hành',
    SalesEInvoiceStatus.issuing => 'Đang phát hành',
    SalesEInvoiceStatus.issued => 'Đã phát hành',
    SalesEInvoiceStatus.sent => 'Đã gửi',
    SalesEInvoiceStatus.failed => 'Phát hành lỗi',
    SalesEInvoiceStatus.cancelled => 'Đã hủy',
  };
}
