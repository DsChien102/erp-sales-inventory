import 'package:erp/features/inventory/logic/stock_policy/stock_policy_cubit.dart';
import 'package:erp/features/inventory/logic/stock_policy/stock_policy_rules.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class ThresholdImpactSheet extends StatelessWidget {
  final StockPolicyCubit cubit;

  const ThresholdImpactSheet({super.key, required this.cubit});

  static Future<void> show(BuildContext context, StockPolicyCubit cubit) {
    return showVAdaptiveSheet(
      context: context,
      title: 'Lưu ${cubit.state.dirtyProductIds.length} thay đổi?',
      child: ThresholdImpactSheet(cubit: cubit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = cubit.state;
    final snapshot = state.snapshot;
    if (snapshot == null) return const SizedBox.shrink();

    final dirtyProducts = snapshot.products
        .where((p) => state.thresholdDrafts.containsKey(p.productId))
        .toList();

    // Tính delta tồn thấp
    final beforeLow = lowCount(
      snapshot.products.map(
        (p) => (
          available: p.available,
          threshold: p.threshold,
          hasExpired: p.hasExpired,
          hasNearExpiry: p.hasNearExpiry,
        ),
      ),
    );

    final afterLow = lowCount(
      snapshot.products.map((p) {
        final applied = state.appliedProduct(p);
        return (
          available: applied.available,
          threshold: applied.threshold,
          hasExpired: applied.hasExpired,
          hasNearExpiry: applied.hasNearExpiry,
        );
      }),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final p in dirtyProducts) ...[
                Builder(
                  builder: (context) {
                    final draft = state.thresholdDrafts[p.productId]!;
                    final oldText = p.configured
                        ? '${p.threshold} / ${p.target}'
                        : 'chưa có';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: VSpacing.space2),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: p.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            TextSpan(
                              text:
                                  ': $oldText → ${draft.threshold} / ${draft.target} ${p.uom}',
                            ),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          color: context.vColors.textPrimary,
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: VSpacing.space2),
              Text(
                'Tồn thấp: $beforeLow → $afterLow sản phẩm',
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w500,
                  color: context.vColors.textPrimary,
                ),
              ),
              const SizedBox(height: VSpacing.space1),
              Text(
                'Thay đổi chính sách không làm đổi số tồn.',
                style: TextStyle(
                  fontSize: 12,
                  height: 18 / 12,
                  color: context.vColors.textSecondary,
                ),
              ),
              const SizedBox(height: VSpacing.space4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  VButton(
                    label: 'Huỷ',
                    variant: VButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: VSpacing.space3),
                  VButton(
                    label: 'Lưu chính sách',
                    variant: VButtonVariant.primary,
                    onPressed: () {
                      Navigator.of(context).pop();
                      cubit.saveThresholds();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

