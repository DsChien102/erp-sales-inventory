import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import '../../logic/price_rule_list_cubit.dart';
import '../../logic/price_rule_list_state.dart';
import 'price_rule_card.dart';

class PriceRuleListView extends StatelessWidget {
  const PriceRuleListView({
    super.key,
    required this.cubit,
    required this.scrollController,
    required this.state,
    this.onRuleTap,
  });

  final PriceRuleListCubit cubit;
  final ScrollController scrollController;
  final PriceRuleListState state;

  /// Điều hướng sang chi tiết — page (apps/erp) quyết định route.
  final ValueChanged<String>? onRuleTap;

  @override
  Widget build(BuildContext context) {
    final items = state.items;
    if (items.isEmpty) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () async => cubit.refresh(),
      child: ListView.separated(
        controller: scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: VSpacing.space4,
          vertical: VSpacing.space2,
        ),
        itemCount: items.length + (state.hasReachedMax ? 0 : 1),
        separatorBuilder: (_, __) => VGap.sm(),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.all(VSpacing.space4),
              child: Center(child: VSkeleton(width: 120, height: 12)),
            );
          }
          final rule = items[index];
          return PriceRuleCard(
            rule: rule,
            onTap: onRuleTap == null ? null : () => onRuleTap!(rule.id),
          );
        },
      ),
    );
  }
}
