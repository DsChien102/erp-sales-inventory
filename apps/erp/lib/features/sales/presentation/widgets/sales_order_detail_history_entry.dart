import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import 'package:erp/features/sales/logic/sales_order_detail_state.dart';
import 'sales_entry_row.dart';

/// Entry row for opening the order history sub-page from SG-08 main scroll.
class SalesOrderDetailHistoryEntry extends StatelessWidget {
  const SalesOrderDetailHistoryEntry({
    super.key,
    required this.status,
    required this.onTap,
    required this.onRetry,
    this.errorMessage,
    this.subtitle = 'Xem thanh toán và các hoạt động của đơn',
    this.showEntryOnIdle = false,
  });

  final SalesOrderDetailSectionStatus status;
  final String? errorMessage;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  /// Mô tả dưới tiêu đề; hub chứng từ SG-08 dùng chữ khác trang chi tiết.
  final String subtitle;

  /// `true`: trạng thái `idle` vẫn hiện entry row thay vì card đang tải.
  final bool showEntryOnIdle;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return switch (status) {
      SalesOrderDetailSectionStatus.idle => showEntryOnIdle ? _entryRow() : _loadingCard(colors),
      SalesOrderDetailSectionStatus.loading => _loadingCard(colors),
      SalesOrderDetailSectionStatus.blocked => _messageCard(
        colors: colors,
        message: errorMessage ?? 'Bạn không có quyền xem lịch sử của đơn này.',
        showRetry: false,
      ),
      SalesOrderDetailSectionStatus.projectionPending => _messageCard(
        colors: colors,
        message: errorMessage ?? 'Lịch sử đang đồng bộ. Thử lại sau.',
        showRetry: true,
      ),
      SalesOrderDetailSectionStatus.error => _messageCard(
        colors: colors,
        message: errorMessage ?? 'Không tải được lịch sử.',
        showRetry: true,
      ),
      SalesOrderDetailSectionStatus.loaded => _entryRow(),
    };
  }

  Widget _entryRow() {
    return SalesEntryRow(
      key: const Key('btn_sg08_history_entry'),
      icon: VIcons.history,
      title: 'Lịch sử',
      subtitle: subtitle,
      onTap: onTap,
    );
  }

  Widget _loadingCard(dynamic colors) {
    return VCard(
      backgroundColor: colors.surface,
      border: Border.all(color: colors.borderDefault),
      padding: const EdgeInsets.all(VSpacing.space3),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          VGap.horizontalMd(),
          Expanded(
            child: VText(
              'Đang tải lịch sử…',
              variant: VTextVariant.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageCard({
    required dynamic colors,
    required String message,
    required bool showRetry,
  }) {
    return VCard(
      backgroundColor: colors.surface,
      border: Border.all(color: colors.borderDefault),
      padding: const EdgeInsets.all(VSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VText(
            'Lịch sử',
            variant: VTextVariant.bodyDefault,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const VGap.xs(),
          VText(
            message,
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          if (showRetry) ...[
            const VGap.sm(),
            VButton(
              label: 'Thử lại',
              onPressed: onRetry,
              variant: VButtonVariant.secondary,
              size: VButtonSize.small,
            ),
          ],
        ],
      ),
    );
  }
}
