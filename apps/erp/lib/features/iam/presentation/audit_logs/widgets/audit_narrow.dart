import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../data/models/tenant_audit_log.dart';
import '../models/audit_log_ui_model.dart';
import 'audit_day_section.dart';
import 'audit_log_category_filter_chips.dart';
import 'audit_log_empty_view.dart';
import 'detail_part.dart';

class AuditNarrow extends StatelessWidget {
  const AuditNarrow({
    super.key,
    required this.searchController,
    required this.isFilterActive,
    required this.selectedCategory,
    required this.rangeSubtitle,
    required this.emptyType,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.items,
    required this.onSearchChanged,
    required this.onOpenFilter,
    required this.onCategorySelected,
    required this.onEmptyAction,
    required this.onItemTap,
    required this.onLoadMore,
  });

  final TextEditingController searchController;
  final bool isFilterActive;
  final TenantAuditEventCategory? selectedCategory;
  final String rangeSubtitle;
  final AuditLogEmptyStateType? emptyType;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final List<AuditLogItemUiModel> items;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilter;
  final ValueChanged<TenantAuditEventCategory?> onCategorySelected;
  final VoidCallback onEmptyAction;
  final ValueChanged<AuditLogItemUiModel> onItemTap;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: colors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VSpacing.screenMobile,
                  VSpacing.space3,
                  VSpacing.screenMobile,
                  VSpacing.space2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: VSearchBar(
                        controller: searchController,
                        hintText: 'Tìm người thực hiện hoặc hoạt động',
                        onChanged: onSearchChanged,
                        onClear: () => onSearchChanged(''),
                      ),
                    ),
                    const VGap.horizontalSm(),
                    _FilterIconButton(
                      isActive: isFilterActive,
                      onPressed: onOpenFilter,
                    ),
                  ],
                ),
              ),
              AuditLogCategoryFilterChips(
                selectedCategory: selectedCategory,
                onCategorySelected: onCategorySelected,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Divider(height: 1, color: colors.borderDefault),
        Expanded(
          child: _buildBody(context, colors),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, VColorScheme colors) {
    if (emptyType != null) {
      return AuditLogEmptyView(
        type: emptyType!,
        onAction: onEmptyAction,
      );
    }

    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: VText(
              rangeSubtitle,
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
          ),
          const Expanded(child: Center(child: VLoading(size: 40))),
        ],
      );
    }

    final grouped = _groupByVietnamDay(items);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
      children: [
        VText(
          rangeSubtitle,
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
        for (final entry in grouped.entries)
          AuditDaySection(
            dayLabel: entry.key,
            items: entry.value,
            onTap: onItemTap,
          ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: VButton(
                label: isLoadingMore ? 'Đang tải...' : 'Tải thêm',
                variant: VButtonVariant.secondary,
                isLoading: isLoadingMore,
                onPressed: isLoadingMore ? null : onLoadMore,
              ),
            ),
          ),
      ],
    );
  }

  Map<String, List<AuditLogItemUiModel>> _groupByVietnamDay(
    List<AuditLogItemUiModel> list,
  ) {
    final map = <String, List<AuditLogItemUiModel>>{};
    for (final item in list) {
      final key = formatAuditDayHeader(item.timestamp);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }
}

class _FilterIconButton extends StatelessWidget {
  const _FilterIconButton({
    required this.isActive,
    required this.onPressed,
  });

  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return IconButton(
      tooltip: isActive ? 'Bộ lọc (đang áp dụng)' : 'Bộ lọc',
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          VIcon(
            icon: VIcons.tune,
            size: 20,
            color: colors.textPrimary,
          ),
          if (isActive)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
