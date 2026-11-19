import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import '../models/sales_order/sales_order_list_filters.dart';

final class SalesOrderFilterSheetResult {
  const SalesOrderFilterSheetResult({
    required this.timeFilter,
    required this.lifecycleFilter,
    required this.settlementFilter,
    required this.postSaleFilter,
    required this.eInvoiceFilter,
  });

  final SalesOrderListTimeFilter timeFilter;
  final SalesOrderListLifecycleFilter lifecycleFilter;
  final SalesOrderListSettlementFilter settlementFilter;
  final SalesOrderListPostSaleFilter postSaleFilter;
  final SalesOrderListEInvoiceFilter eInvoiceFilter;
}

class SalesOrderFilterBottomSheet extends StatefulWidget {
  const SalesOrderFilterBottomSheet({
    super.key,
    required this.initialTime,
    required this.initialLifecycle,
    required this.initialSettlement,
    required this.initialPostSale,
    required this.initialEInvoice,
  });

  final SalesOrderListTimeFilter initialTime;
  final SalesOrderListLifecycleFilter initialLifecycle;
  final SalesOrderListSettlementFilter initialSettlement;
  final SalesOrderListPostSaleFilter initialPostSale;
  final SalesOrderListEInvoiceFilter initialEInvoice;

  static Future<SalesOrderFilterSheetResult?> show(
    BuildContext context, {
    required SalesOrderListTimeFilter timeFilter,
    required SalesOrderListLifecycleFilter lifecycleFilter,
    required SalesOrderListSettlementFilter settlementFilter,
    required SalesOrderListPostSaleFilter postSaleFilter,
    required SalesOrderListEInvoiceFilter eInvoiceFilter,
  }) {
    return showVBottomSheet<SalesOrderFilterSheetResult>(
      context: context,
      child: SalesOrderFilterBottomSheet(
        initialTime: timeFilter,
        initialLifecycle: lifecycleFilter,
        initialSettlement: settlementFilter,
        initialPostSale: postSaleFilter,
        initialEInvoice: eInvoiceFilter,
      ),
    );
  }

  @override
  State<SalesOrderFilterBottomSheet> createState() => _SalesOrderFilterBottomSheetState();
}

class _SalesOrderFilterBottomSheetState extends State<SalesOrderFilterBottomSheet> {
  late SalesOrderListTimeFilter _time = widget.initialTime;
  late SalesOrderListLifecycleFilter _lifecycle = widget.initialLifecycle;
  late SalesOrderListSettlementFilter _settlement = widget.initialSettlement;
  late SalesOrderListPostSaleFilter _postSale = widget.initialPostSale;
  late SalesOrderListEInvoiceFilter _eInvoice = widget.initialEInvoice;

  void _reset() {
    Navigator.of(context).pop(
      const SalesOrderFilterSheetResult(
        timeFilter: SalesOrderListTimeFilter.all,
        lifecycleFilter: SalesOrderListLifecycleFilter.all,
        settlementFilter: SalesOrderListSettlementFilter.all,
        postSaleFilter: SalesOrderListPostSaleFilter.all,
        eInvoiceFilter: SalesOrderListEInvoiceFilter.all,
      ),
    );
  }

  void _apply() {
    Navigator.of(context).pop(
      SalesOrderFilterSheetResult(
        timeFilter: _time,
        lifecycleFilter: _lifecycle,
        settlementFilter: _settlement,
        postSaleFilter: _postSale,
        eInvoiceFilter: _eInvoice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        VPagePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VGap.md(),
              _sectionTitle('Thời gian'),
              const VGap.sm(),
              Wrap(
                spacing: VSpacing.space2,
                runSpacing: VSpacing.space2,
                children: [
                  for (final option in SalesOrderListTimeFilter.values)
                    VChip(
                      label: _timeLabel(option),
                      tone: _time == option
                          ? VComponentTone.primary
                          : VComponentTone.neutral,
                      onTap: () => setState(() => _time = option),
                    ),
                ],
              ),
              const VGap.md(),
              _sectionTitle('Trạng thái đơn'),
              const VGap.sm(),
              Wrap(
                spacing: VSpacing.space2,
                runSpacing: VSpacing.space2,
                children: [
                  for (final option in SalesOrderListLifecycleFilter.values)
                    VChip(
                      label: _lifecycleLabel(option),
                      tone: _lifecycle == option
                          ? VComponentTone.primary
                          : VComponentTone.neutral,
                      onTap: () => setState(() => _lifecycle = option),
                    ),
                ],
              ),
              const VGap.md(),
              _sectionTitle('Thanh toán'),
              const VGap.sm(),
              Wrap(
                spacing: VSpacing.space2,
                runSpacing: VSpacing.space2,
                children: [
                  for (final option in SalesOrderListSettlementFilter.values)
                    VChip(
                      label: _settlementLabel(option),
                      tone: _settlement == option
                          ? VComponentTone.primary
                          : VComponentTone.neutral,
                      onTap: () => setState(() => _settlement = option),
                    ),
                ],
              ),
              const VGap.md(),
              _sectionTitle('Sau bán'),
              const VGap.sm(),
              Wrap(
                spacing: VSpacing.space2,
                runSpacing: VSpacing.space2,
                children: [
                  for (final option in SalesOrderListPostSaleFilter.values)
                    VChip(
                      label: _postSaleLabel(option),
                      tone: _postSale == option
                          ? VComponentTone.primary
                          : VComponentTone.neutral,
                      onTap: () => setState(() => _postSale = option),
                    ),
                ],
              ),
              const VGap.md(),
              _sectionTitle('Hóa đơn điện tử'),
              const VGap.sm(),
              Wrap(
                spacing: VSpacing.space2,
                runSpacing: VSpacing.space2,
                children: [
                  for (final option in SalesOrderListEInvoiceFilter.values)
                    VChip(
                      label: _eInvoiceLabel(option),
                      tone: _eInvoice == option
                          ? VComponentTone.primary
                          : VComponentTone.neutral,
                      onTap: () => setState(() => _eInvoice = option),
                    ),
                ],
              ),
              const VGap.md(),
            ],
          ),
        ),
        VPagePadding(
          child: Row(
            children: [
              Expanded(
                child: VButton(
                  variant: VButtonVariant.secondary,
                  label: 'Đặt lại',
                  foregroundColor: colors.textPrimary,
                  onPressed: _reset,
                ),
              ),
              const VGap.horizontalSm(),
              Expanded(
                child: VButton(
                  variant: VButtonVariant.primary,
                  label: 'Áp dụng',
                  onPressed: _apply,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return VText(
      title,
      variant: VTextVariant.bodyDefault,
      color: context.vColors.textPrimary,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }

  String _timeLabel(SalesOrderListTimeFilter value) => switch (value) {
    SalesOrderListTimeFilter.all => 'Tất cả',
    SalesOrderListTimeFilter.today => 'Hôm nay',
    SalesOrderListTimeFilter.last7Days => '7 ngày',
    SalesOrderListTimeFilter.last30Days => '30 ngày',
  };

  String _lifecycleLabel(SalesOrderListLifecycleFilter value) => switch (value) {
    SalesOrderListLifecycleFilter.all => 'Tất cả',
    SalesOrderListLifecycleFilter.completed => 'Hoàn tất',
    SalesOrderListLifecycleFilter.cancelled => 'Đã hủy',
  };

  String _settlementLabel(SalesOrderListSettlementFilter value) => switch (value) {
    SalesOrderListSettlementFilter.all => 'Tất cả',
    SalesOrderListSettlementFilter.paid => 'Đã thanh toán',
    SalesOrderListSettlementFilter.outstandingReceivable => 'Còn phải thu',
    SalesOrderListSettlementFilter.unpaid => 'Chưa thu',
  };

  String _postSaleLabel(SalesOrderListPostSaleFilter value) => switch (value) {
    SalesOrderListPostSaleFilter.all => 'Tất cả',
    SalesOrderListPostSaleFilter.hasReturnExchange => 'Có đổi/trả',
  };

  String _eInvoiceLabel(SalesOrderListEInvoiceFilter value) => switch (value) {
    SalesOrderListEInvoiceFilter.all => 'Tất cả',
    SalesOrderListEInvoiceFilter.pending => 'Chưa phát hành',
    SalesOrderListEInvoiceFilter.issued => 'Đã phát hành',
  };
}
