import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';

import 'price_rule_history_filter_sheet.dart';
import 'price_rule_history_shared.dart';
import 'price_rule_history_states.dart';
import 'price_rule_history_timeline_tile.dart';

/// SG-06 — Full Timeline lịch sử giá riêng (D-02, D-04, D-08 system states).
class PriceRuleHistoryView extends StatefulWidget {
  const PriceRuleHistoryView({
    super.key,
    required this.items,
    required this.hasMore,
    required this.onLoadMore,
    this.customerName,
    this.productUnitName,
    this.status,
    this.isLoading = false,
    this.errorMessage,
    this.hasPermission = true,
    this.hasSensitivePermission = true,
    this.onRetry,
    this.onBack,
    this.onViewRuleDetail,
  });

  final List<CustomerPriceRuleActivityDto> items;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final String? customerName;
  final String? productUnitName;
  final CustomerPriceRuleDerivedStatus? status;
  final bool isLoading;
  final String? errorMessage;
  final bool hasPermission;
  final bool hasSensitivePermission;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;
  final VoidCallback? onViewRuleDetail;

  @override
  State<PriceRuleHistoryView> createState() => _PriceRuleHistoryViewState();
}

enum _HistoryQuickFilter { all, priceEdit, fromOrder, excelImport }

class _PriceRuleHistoryViewState extends State<PriceRuleHistoryView> {
  _HistoryQuickFilter _quickFilter = _HistoryQuickFilter.all;
  PriceRuleHistoryFilterState _filterState =
      const PriceRuleHistoryFilterState();
  final TextEditingController _search = TextEditingController();
  bool _isNewestFirst = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CustomerPriceRuleActivityDto> get _filtered {
    final q = _search.text.trim().toLowerCase();
    var list = widget.items.where((item) {
      // Quick filter
      final matchQuick = switch (_quickFilter) {
        _HistoryQuickFilter.all => true,
        _HistoryQuickFilter.priceEdit =>
          item.activityType == CustomerPriceRuleActivityType.updated ||
              item.activityType == CustomerPriceRuleActivityType.created,
        _HistoryQuickFilter.fromOrder =>
          item.activityType == CustomerPriceRuleActivityType.memoryCreated ||
              item.activityType == CustomerPriceRuleActivityType.memoryUpdated,
        _HistoryQuickFilter.excelImport =>
          item.activityType == CustomerPriceRuleActivityType.importCreated ||
              item.activityType == CustomerPriceRuleActivityType.importUpdated,
      };
      if (!matchQuick) return false;

      // Bottom sheet filter
      if (_filterState.isFiltered) {
        if (_filterState.activityType != 'Tất cả') {
          final label = PriceRuleHistoryShared.activityLabel(item.activityType);
          if (label != _filterState.activityType) return false;
        }
        if (_filterState.source != 'Tất cả') {
          final srcLabel = PriceRuleHistoryShared.sourceLabel(item.sourceType);
          if (srcLabel != _filterState.source) return false;
        }
        if (_filterState.actor != 'Tất cả') {
          if (item.actor.displayName != _filterState.actor) return false;
        }
        if (_filterState.timeRange != 'Tất cả') {
          if (!PriceRuleHistoryShared.matchesTimeRange(
            _filterState.timeRange,
            item.createdAt,
          )) {
            return false;
          }
        }
      }

      if (q.isEmpty) return true;
      final label = PriceRuleHistoryShared.activityLabel(
        item.activityType,
      ).toLowerCase();
      final actor = item.actor.displayName.toLowerCase();
      return label.contains(q) || actor.contains(q);
    }).toList();

    if (!_isNewestFirst) {
      list = list.reversed.toList();
    }
    return list;
  }

  void _openFilterSheet() async {
    final actors = <String>{'Tất cả'};
    for (final item in widget.items) {
      actors.add(item.actor.displayName);
    }
    final result = await PriceRuleHistoryFilterSheet.show(
      context: context,
      initialFilter: _filterState,
      actorOptions: actors.toList()..sort(),
    );
    if (result != null) {
      setState(() => _filterState = result);
    }
  }

  void _resetAllFilters() {
    setState(() {
      _quickFilter = _HistoryQuickFilter.all;
      _filterState = const PriceRuleHistoryFilterState();
      _search.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    // D-08 System states: No permission
    if (!widget.hasPermission) {
      return PriceRuleHistorySystemStateView(
        icon: VIcons.lock,
        tone: VComponentTone.neutral,
        title: 'Bạn không có quyền xem lịch sử giá riêng',
        description: 'Vui lòng liên hệ quản trị viên để được cấp quyền.',
        buttonLabel: 'Quay lại',
        onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
      );
    }

    // D-08 System states: Error
    if (widget.errorMessage != null && widget.errorMessage!.isNotEmpty) {
      return PriceRuleHistorySystemStateView(
        icon: VIcons.error,
        tone: VComponentTone.danger,
        title: 'Không tải được lịch sử',
        description: widget.errorMessage!,
        buttonLabel: 'Thử lại',
        onPressed: widget.onRetry,
      );
    }

    // D-08 System states: Loading
    if (widget.isLoading) {
      return const PriceRuleHistorySkeletonView();
    }

    final filtered = _filtered;

    return Column(
      children: [
        // Search bar + Filter Icon Button
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.space4,
            VSpacing.space3,
            VSpacing.space4,
            VSpacing.space2,
          ),
          child: Row(
            children: [
              Expanded(
                child: VSearchBar(
                  hintText: 'Tìm theo hành động, người thực hiện...',
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const VGap.horizontalSm(),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  VIconBox(
                    icon: VIcons.tune,
                    size: 44,
                    iconSize: 20,
                    backgroundColor:
                        (_filterState.isFiltered ||
                            _quickFilter != _HistoryQuickFilter.all)
                        ? colors.primary.withValues(alpha: 0.1)
                        : colors.surface,
                    iconColor:
                        (_filterState.isFiltered ||
                            _quickFilter != _HistoryQuickFilter.all)
                        ? colors.primary
                        : colors.textPrimary,
                    borderColor:
                        (_filterState.isFiltered ||
                            _quickFilter != _HistoryQuickFilter.all)
                        ? colors.primary
                        : colors.borderDefault,
                    borderRadius: VRadius.button,
                    onTap: _openFilterSheet,
                  ),
                  if (_filterState.isFiltered ||
                      _quickFilter != _HistoryQuickFilter.all)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        if (widget.customerName != null || widget.productUnitName != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
            child: Row(
              children: [
                if (widget.customerName != null)
                  VText(
                    widget.customerName!,
                    variant: VTextVariant.bodyDefault,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                if (widget.productUnitName != null) ...[
                  const VGap.horizontalXs(),
                  VText(
                    widget.productUnitName!,
                    variant: VTextVariant.caption,
                    color: colors.textMuted,
                  ),
                ],
              ],
            ),
          ),
          const VGap.xs(),
        ],

        // Quick Filter Chips (D-02)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
          child: Row(
            spacing: VSpacing.sm,
            children: [
              for (final entry in _HistoryQuickFilter.values)
                VChip(
                  label: switch (entry) {
                    _HistoryQuickFilter.all => 'Tất cả',
                    _HistoryQuickFilter.priceEdit => 'Sửa giá',
                    _HistoryQuickFilter.fromOrder => 'Từ đơn hàng',
                    _HistoryQuickFilter.excelImport => 'Nhập Excel',
                  },
                  selected: _quickFilter == entry,
                  onTap: () => setState(() => _quickFilter = entry),
                ),
            ],
          ),
        ),

        // Active filter tags bar (D-04 A)
        if (_filterState.isFiltered) ...[
          const VGap.xs(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
            child: Row(
              children: [
                if (_filterState.activityType != 'Tất cả') ...[
                  VChip(
                    label: '${_filterState.activityType} ✕',
                    selected: true,
                    onTap: () => setState(
                      () => _filterState = _filterState.copyWith(
                        activityType: 'Tất cả',
                      ),
                    ),
                  ),
                  const VGap.horizontalXs(),
                ],
                if (_filterState.timeRange != 'Tất cả') ...[
                  VChip(
                    label: '${_filterState.timeRange} ✕',
                    selected: true,
                    onTap: () => setState(
                      () => _filterState = _filterState.copyWith(
                        timeRange: 'Tất cả',
                      ),
                    ),
                  ),
                  const VGap.horizontalXs(),
                ],
                VButton(
                  label: 'Xóa lọc',
                  variant: VButtonVariant.tertiary,
                  size: VButtonSize.small,
                  foregroundColor: colors.danger,
                  onPressed: _resetAllFilters,
                ),
              ],
            ),
          ),
        ],

        // Sort & Result counter header row
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.space4,
            VSpacing.space2,
            VSpacing.space4,
            VSpacing.space1,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VText(
                '${filtered.length} kết quả',
                variant: VTextVariant.caption,
                color: colors.textMuted,
              ),
              InkWell(
                onTap: () => setState(() => _isNewestFirst = !_isNewestFirst),
                child: Row(
                  children: [
                    VText(
                      _isNewestFirst ? 'Mới nhất trước' : 'Cũ nhất trước',
                      variant: VTextVariant.caption,
                      color: colors.textSecondary,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const VGap.horizontalXs(),
                    VIcon(
                      icon: VIcons.chevronDown,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Timeline List or Empty state (D-04 B & D-08 1)
        Expanded(
          child: filtered.isEmpty
              ? PriceRuleHistoryEmptyView(
                  isFiltered:
                      _filterState.isFiltered ||
                      _quickFilter != _HistoryQuickFilter.all ||
                      _search.text.isNotEmpty,
                  onReset: _resetAllFilters,
                  onBack: widget.onBack,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  itemCount: filtered.length + (widget.hasMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == filtered.length) {
                      widget.onLoadMore();
                      return const Padding(
                        padding: EdgeInsets.all(VSpacing.space4),
                        child: Center(child: VSkeleton(width: 40, height: 40)),
                      );
                    }
                    final item = filtered[i];
                    final isLastItem = i == filtered.length - 1;
                    return PriceRuleHistoryTimelineTile(
                      activity: item,
                      isLast: isLastItem,
                      hasSensitivePermission: widget.hasSensitivePermission,
                      onViewRuleDetail: widget.onViewRuleDetail,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
