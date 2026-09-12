import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// D-04 — Không tìm thấy đơn nháp.
class SalesDraftListNoResultState extends StatelessWidget {
  const SalesDraftListNoResultState({
    super.key,
    required this.query,
    required this.onClearSearch,
  });

  final String query;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VEmptyState(
      key: const Key('wgt_e01_u01_no_result'),
      filled: true,
      border: VBorders.all(colors.borderDefault),
      backgroundColor: colors.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          VEmptyHeader(
            children: [
              VEmptyMedia(icon: VIcons.search),
              VEmptyTitle('Không tìm thấy đơn nháp'),
              VEmptyDescription('Không có đơn nháp phù hợp với \'$query\'.'),
            ],
          ),
          const VGap.xs(),
          VEmptyContent(
            child: VButton(
              key: const Key('btn_draft_clear_search'),
              label: 'Xóa tìm kiếm',
              variant: VButtonVariant.tertiary,
              tone: VComponentTone.success,
              onPressed: onClearSearch,
            ),
          ),
        ],
      ),
    );
  }
}
