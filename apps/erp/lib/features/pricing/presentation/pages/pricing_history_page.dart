import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/pricing/data/customer_price_rule_repository.dart';
import 'package:erp/features/pricing/presentation.dart';

/// SG-06 D-02 — Lịch sử áp dụng & thay đổi giá riêng (US-10).
class PricingHistoryPage extends StatefulWidget {
  const PricingHistoryPage({super.key, required this.ruleId});

  final String ruleId;

  @override
  State<PricingHistoryPage> createState() => _PricingHistoryPageState();
}

class _PricingHistoryPageState extends State<PricingHistoryPage> {
  late final PriceRuleHistoryCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = PriceRuleHistoryCubit(
      ruleId: widget.ruleId,
      repository: GetIt.instance<CustomerPriceRuleRepository>(),
    )..fetchHistory();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<PriceRuleHistoryCubit, PriceRuleHistoryState>(
        builder: (context, state) {
          final rule = state.ruleContext;
          return VPageScaffold(
            key: const Key('wgt_e02_u10_fr01_01'),
            title: 'Lịch sử giá riêng',
            subtitle: rule?.customer.displayName,
            showBackButton: true,
            body: PriceRuleHistoryView(
              items: state.items,
              hasMore: !state.hasReachedMax,
              onLoadMore: () => _cubit.fetchHistory(),
              customerName: rule?.customer.displayName,
              productUnitName: rule == null
                  ? null
                  : '${rule.productUnit.productName} · ${rule.productUnit.unitName}',
              status: rule?.derivedStatus,
              isLoading: state is PriceRuleHistoryLoading && state.isFirstLoad,
              errorMessage: state is PriceRuleHistoryError ? state.message : null,
              hasPermission: state.hasPermission,
              hasSensitivePermission: state.hasSensitivePermission,
              onRetry: () => _cubit.refresh(),
              onBack: () => context.pop(),
              onViewRuleDetail: () => context.pop(),
            ),
          );
        },
      ),
    );
  }
}
