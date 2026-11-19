import 'package:erp/features/inventory/logic/stock_policy/stock_policy_cubit.dart';
import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class NearExpiryAddSheet extends StatelessWidget {
  final StockPolicyCubit cubit;

  const NearExpiryAddSheet({super.key, required this.cubit});

  static Future<void> show(BuildContext context, StockPolicyCubit cubit) {
    return showVAdaptiveSheet(
      context: context,
      title: 'Thêm sản phẩm',
      child: NearExpiryAddSheet(cubit: cubit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = cubit.state;
    final snapshot = state.snapshot;
    if (snapshot == null) return const SizedBox.shrink();

    final taken = state.expiryDraft.overrides.map((o) => o.productId).toSet();
    final options = snapshot.products
        .where((p) => p.isLotTracked && !taken.contains(p.productId))
        .toList();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (options.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: VSpacing.space3),
                  child: Text(
                    'Mọi sản phẩm theo lô đều đã có chính sách riêng.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 18 / 12,
                      color: context.vColors.textSecondary,
                    ),
                  ),
                )
              else
                for (var i = 0; i < options.length; i++) ...[
                  VListRow(
                    title: options[i].name,
                    subtitle: options[i].code,
                    type: VListRowType.navigation,
                    onTap: () {
                      Navigator.of(context).pop();
                      cubit.addOverride(options[i].productId);
                    },
                  ),
                  if (i < options.length - 1) const SizedBox(height: VSpacing.space2),
                ],
              const SizedBox(height: VSpacing.space4),
              Align(
                alignment: Alignment.centerRight,
                child: VButton(
                  label: 'Đóng',
                  variant: VButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

