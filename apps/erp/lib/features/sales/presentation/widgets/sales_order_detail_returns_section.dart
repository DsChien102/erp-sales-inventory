import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/sales/logic/sales_order_detail_state.dart';
import '../models/sales_order/sales_order_detail_vm.dart';
import 'sales_entry_row.dart';

class SalesOrderDetailReturnsSection extends StatelessWidget {
  const SalesOrderDetailReturnsSection({
    super.key,
    required this.slips,
    required this.status,
    required this.onTap,
    required this.onRetry,
  });

  final List<SalesReturnExchangeSlipItemVm> slips;
  final SalesOrderDetailSectionStatus status;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return switch (status) {
      SalesOrderDetailSectionStatus.idle ||
      SalesOrderDetailSectionStatus.loading => _loadingCard(colors),
      SalesOrderDetailSectionStatus.blocked => _messageCard(
        colors: colors,
        message: 'Bạn không có quyền xem phiếu đổi/trả của đơn này.',
        showRetry: false,
      ),
      SalesOrderDetailSectionStatus.projectionPending => _messageCard(
        colors: colors,
        message: 'Phiếu đổi/trả đang đồng bộ. Thử lại sau.',
        showRetry: true,
      ),
      SalesOrderDetailSectionStatus.error => _messageCard(
        colors: colors,
        message: 'Không tải được phiếu đổi/trả.',
        showRetry: true,
      ),
      SalesOrderDetailSectionStatus.loaded => _loadedEntry(),
    };
  }

  Widget _loadedEntry() {
    if (slips.isEmpty) {
      return const SizedBox.shrink();
    }
    final newestDate = slips.first.dateFormatted;
    return SalesEntryRow(
      key: const Key('btn_sg08_returns_entry'),
      icon: VIcons.history,
      title: 'Phiếu đổi/trả',
      subtitle: '${slips.length} phiếu · Mới nhất $newestDate',
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
              'Đang tải phiếu đổi/trả…',
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
            'Phiếu đổi/trả',
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
