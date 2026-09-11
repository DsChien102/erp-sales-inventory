import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';

import '../cubit/price_rule_list_cubit.dart';
import '../cubit/price_rule_list_state.dart';
import '../models/price_rule_list_filters.dart';
import 'price_rule_filter_bottom_sheet.dart';
import 'price_rule_sort_bottom_sheet.dart';

/// Search + quick chips + filter button + sort row (SG-01 D-01/D-03/D-05).
class PriceRuleListSearchAndFilter extends StatefulWidget {
  const PriceRuleListSearchAndFilter({super.key, required this.cubit});

  final PriceRuleListCubit cubit;

  @override
  State<PriceRuleListSearchAndFilter> createState() =>
      _PriceRuleListSearchAndFilterState();
}

class _PriceRuleListSearchAndFilterState
    extends State<PriceRuleListSearchAndFilter> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final _filters = const [
    (CustomerPriceRuleQuickFilter.all, 'Tất cả'),
    (CustomerPriceRuleQuickFilter.applying, 'Đang áp dụng'),
    (CustomerPriceRuleQuickFilter.belowFloor, 'Dưới giá sàn'),
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      widget.cubit.search(value);
    });
  }

  Future<void> _openFilter(PriceRuleListState state) async {
    final result = await PriceRuleFilterBottomSheet.show(
      context,
      initial: state.advancedFilter,
    );
    if (result != null) {
      widget.cubit.applyAdvancedFilter(result);
    }
  }

  Future<void> _openSort(PriceRuleListState state) async {
    final result = await PriceRuleSortBottomSheet.show(
      context,
      initialSort: state.sortOption,
    );
    if (result != null) {
      widget.cubit.applySort(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PriceRuleListCubit, PriceRuleListState>(
      bloc: widget.cubit,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                      controller: _searchController,
                      hintText: 'Tìm theo khách hàng, SĐT, sản phẩm...',
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  const VGap.horizontalSm(),
                  _FilterButton(
                    activeCount: state.advancedFilter.activeCount,
                    onPressed: () => _openFilter(state),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
              child: Row(
                spacing: VSpacing.sm,
                children: _filters.map((f) {
                  final (filter, label) = f;
                  final isActive = state.quickFilter == filter;
                  return VChip(
                    label: label,
                    selected: isActive,
                    onTap: () => widget.cubit.applyQuickFilter(filter),
                  );
                }).toList(),
              ),
            ),
            const VGap.sm(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
              child: Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () => _openSort(state),
                  borderRadius: BorderRadius.circular(VRadius.r8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: VSpacing.space1,
                      horizontal: VSpacing.space1,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VText(
                          'Sắp xếp: ${state.sortOption.label}',
                          variant: VTextVariant.bodySmall,
                          color: context.vColors.primary,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const VGap.horizontalXs(),
                        VIcon(
                          icon: VIcons.chevronRight,
                          size: 16,
                          color: context.vColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const VGap.sm(),
          ],
        );
      },
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.onPressed,
    required this.activeCount,
  });

  final VoidCallback onPressed;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isActive = activeCount > 0;

    return Badge(
      isLabelVisible: isActive,
      label: VText('$activeCount', variant: VTextVariant.monoNumeric),
      backgroundColor: colors.primary,
      offset: const Offset(4, -4),
      child: VIconBox(
        icon: VIcons.tune,
        size: 44,
        iconSize: 20,
        backgroundColor: isActive
            ? colors.primary.withValues(alpha: 0.1)
            : colors.surface,
        iconColor: isActive ? colors.primary : colors.textPrimary,
        borderColor: isActive ? colors.primary : colors.borderDefault,
        borderRadius: VRadius.button,
        onTap: onPressed,
      ),
    );
  }
}
