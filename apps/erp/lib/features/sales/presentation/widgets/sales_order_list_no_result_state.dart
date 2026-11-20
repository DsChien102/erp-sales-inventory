import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class SalesOrderListNoResultState extends StatelessWidget {
  const SalesOrderListNoResultState({
    super.key,
    this.searchTerm,
    this.onClearSearch,
    this.onClearFilters,
  });

  final String? searchTerm;
  final VoidCallback? onClearSearch;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final action = onClearSearch ?? onClearFilters;
    final colors = context.vColors;
    final trimmedQuery = searchTerm?.trim();
    final description = (trimmedQuery != null && trimmedQuery.isNotEmpty)
        ? 'Không có đơn phù hợp với “$trimmedQuery”\ntrong phạm vi hiện tại.'
        : 'Không có đơn phù hợp trong phạm vi hiện tại.';

    return VEmptyState(
      key: const Key('wgt_e03_u01_scn06_no_result'),
      bordered: true,
      backgroundColor: colors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VEmptyHeader(
            children: [
              const VEmptyMedia(icon: VIcons.search),
              const VEmptyTitle('Không tìm thấy đơn hàng'),
              VEmptyDescription(description),
            ],
          ),
          const VGap(VSpacing.space2),
          VEmptyContent(
            child: VButton(
              label: 'Xóa tìm kiếm',
              variant: VButtonVariant.tertiary,
              onPressed: action,
            ),
          ),
        ],
      ),
    );
  }
}
