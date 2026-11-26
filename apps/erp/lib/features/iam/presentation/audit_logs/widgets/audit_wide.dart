import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../data/models/tenant_audit_log.dart';
import '../../shared/admin_table.dart';
import '../models/audit_log_ui_model.dart';
import 'audit_log_category_filter_chips.dart';
import 'audit_log_empty_view.dart';
import 'detail_part.dart';

class AuditWide extends StatelessWidget {
  const AuditWide({
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

    const columns = [
      AdminTableColumn('Hoạt động', flex: 1.6, minWidth: 260),
      AdminTableColumn('Người thực hiện', flex: 1.2),
      AdminTableColumn('Đối tượng', flex: 1.2),
      AdminTableColumn('Thời điểm', flex: 0.9),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: colors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: AuditLogCategoryFilterChips(
                  selectedCategory: selectedCategory,
                  onCategorySelected: onCategorySelected,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 320,
                child: VSearchBar(
                  controller: searchController,
                  hintText: 'Tìm người thực hiện hoặc hoạt động',
                  onChanged: onSearchChanged,
                  onClear: () => onSearchChanged(''),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: isFilterActive ? 'Bộ lọc (đang áp dụng)' : 'Bộ lọc',
                onPressed: onOpenFilter,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    VIcon(
                      icon: VIcons.tune,
                      size: 20,
                      color: colors.textPrimary,
                    ),
                    if (isFilterActive)
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
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.borderDefault),
        Expanded(
          child: AdminTablePage(
            children: [
              VText(
                rangeSubtitle,
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
              const SizedBox(height: 16),
              if (emptyType != null)
                AdminTable(
                  columns: columns,
                  rows: const [],
                  state: AuditLogEmptyView(
                    type: emptyType!,
                    flat: true,
                    onAction: onEmptyAction,
                  ),
                )
              else if (isLoading)
                const AdminTable(
                  columns: columns,
                  rows: [],
                  loadingRows: 5,
                  semanticLabel: 'Đang tải',
                )
              else
                AdminTable(
                  columns: columns,
                  semanticLabel: 'Lịch sử quản trị',
                  rows: items.map((log) {
                    final resultBadge = auditNonSuccessBadge(log.status);
                    final isLegacy =
                        log.subjectDisplayOrigin == TenantAuditDisplayOrigin.current;
                    final subjectType = log.targetSubjectLabel ?? 'Đối tượng';
                    final subjectName =
                        log.subjectName.isEmpty ? log.targetOrg : log.subjectName;

                    return AdminTableRow(
                      semanticLabel: log.title,
                      onTap: () => onItemTap(log),
                      cells: [
                        Row(
                          children: [
                            AuditIconBox(icon: log.icon),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  VText(
                                    log.title,
                                    variant: VTextVariant.bodyDefault,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  ?resultBadge,
                                  if (isLegacy)
                                    const VBadge(
                                      label: 'Thông tin hiện tại',
                                      tone: VComponentTone.neutral,
                                      variant: VBadgeVariant.soft,
                                      isSmall: true,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        VText(
                          formatAuditActorSummary(log),
                          variant: VTextVariant.bodyDefault,
                          color: colors.textSecondary,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VText(
                              subjectType,
                              variant: VTextVariant.caption,
                              color: colors.textSecondary,
                            ),
                            VText(
                              subjectName,
                              variant: VTextVariant.bodyDefault,
                              color: colors.textPrimary,
                            ),
                          ],
                        ),
                        Text(
                          formatAuditTimestamp(log.timestamp),
                          style: VTypography.bodyDefault.copyWith(
                            color: colors.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    );
                  }).toList(growable: false),
                ),
              if (emptyType == null && !isLoading && hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
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
          ),
        ),
      ],
    );
  }
}
