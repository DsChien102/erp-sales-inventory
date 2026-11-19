import 'package:erp/features/inventory/data/stock_policy/stock_policy_models.dart';
import 'package:erp/features/inventory/logic/stock/stock_indicator_rules.dart';
import 'package:erp/features/inventory/logic/stock_policy/stock_policy_cubit.dart';
import 'package:erp/features/inventory/logic/stock_policy/stock_policy_rules.dart';
import 'package:erp/features/inventory/logic/stock_policy/stock_policy_state.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/patterns/k7_edit_cell.dart';
import 'package:erp/features/inventory/presentation/stock/stock_indicator_badge.dart';
import 'package:erp/features/inventory/presentation/stock_policy/threshold_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class StockThresholdTab extends StatelessWidget {
  final StockPolicyCubit cubit;

  const StockThresholdTab({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final state = cubit.state;
    final snapshot = state.snapshot;
    if (snapshot == null) return const SizedBox.shrink();

    final allProducts = snapshot.products;
    final unsetCount = allProducts.where((p) => !p.configured).length;

    final visibleProducts = state.filter == ThresholdFilter.all
        ? allProducts
        : allProducts.where((p) => !p.configured).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        K7FilterChips(
          items: [
            K7Filter(
              key: 'all',
              label: 'Tất cả',
              count: allProducts.length,
            ),
            K7Filter(
              key: 'unset',
              label: 'Chưa có ngưỡng',
              count: unsetCount,
            ),
          ],
          selected: state.filter == ThresholdFilter.all ? 'all' : 'unset',
          onSelected: (key) => cubit.setFilter(
            key == 'all' ? ThresholdFilter.all : ThresholdFilter.unset,
          ),
        ),
        const SizedBox(height: VSpacing.space3),
        if (visibleProducts.isEmpty)
          InventoryEmpty(
            title: 'Không còn sản phẩm nào chưa có ngưỡng',
            description: 'Mọi sản phẩm đã có ngưỡng cảnh báo.',
            actionLabel: 'Xem tất cả',
            onAction: () => cubit.setFilter(ThresholdFilter.all),
          )
        else
          K7Table<StockPolicyProduct>(
            columns: [
              K7Column(
                label: 'Sản phẩm',
                cell: (p) {
                  final isDirty = state.thresholdDrafts.containsKey(p.productId);
                  return Row(
                    children: [
                      if (isDirty) ...[
                        Semantics(
                          label: 'Đã sửa',
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2F7A3A),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              p.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                color: context.vColors.textPrimary,
                              ),
                            ),
                            Text(
                              p.code,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                                color: context.vColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              K7Column(
                label: 'ĐVT',
                cell: (p) => Text(
                  p.uom,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.vColors.textPrimary,
                  ),
                ),
              ),
              K7Column(
                label: 'Khả dụng',
                numeric: true,
                cell: (p) => Text(
                  '${p.available}',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'JetBrainsMono',
                    color: context.vColors.textPrimary,
                  ),
                ),
              ),
              K7Column(
                label: 'Ngưỡng cảnh báo',
                numeric: true,
                cell: (p) {
                  final draft = state.shownThreshold(p);
                  return K7EditCell(
                    value: draft.threshold,
                    enabled: !state.readOnly,
                    unit: p.uom,
                    semanticLabel: 'Ngưỡng cảnh báo — ${p.name}',
                    onChanged: (val) => cubit.editThreshold(
                      p.productId,
                      threshold: val,
                    ),
                  );
                },
              ),
              K7Column(
                label: 'Mức tồn mục tiêu',
                numeric: true,
                cell: (p) {
                  final draft = state.shownThreshold(p);
                  final err = thresholdRowError(
                    draft.threshold,
                    draft.target,
                    configured: p.configured,
                  );
                  return K7EditCell(
                    value: draft.target,
                    enabled: !state.readOnly,
                    unit: p.uom,
                    errorText: err,
                    semanticLabel: 'Mức tồn mục tiêu — ${p.name}',
                    onChanged: (val) => cubit.editThreshold(
                      p.productId,
                      target: val,
                    ),
                  );
                },
              ),
              K7Column(
                label: 'Chỉ báo',
                cell: (p) {
                  final applied = state.appliedProduct(p);
                  final inds = stockIndicators(
                    available: applied.available,
                    threshold: applied.threshold,
                    hasExpired: applied.hasExpired,
                    hasNearExpiry: applied.hasNearExpiry,
                  );
                  return StockIndicatorBadge(indicators: inds);
                },
              ),
            ],
            rows: visibleProducts,
            mobileRow: (p) {
              final sub = p.configured
                  ? 'Ngưỡng ${p.threshold} · Mục tiêu ${p.target} ${p.uom}'
                  : 'Chưa có ngưỡng';
              final applied = state.appliedProduct(p);
              final inds = stockIndicators(
                available: applied.available,
                threshold: applied.threshold,
                hasExpired: applied.hasExpired,
                hasNearExpiry: applied.hasNearExpiry,
              );
              return VListRow(
                asCard: true,
                title: p.name,
                subtitle: sub,
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: StockIndicatorBadge(indicators: inds),
                ),
                type: state.readOnly
                    ? VListRowType.plain
                    : VListRowType.navigation,
                onTap: state.readOnly
                    ? null
                    : () => ThresholdEditSheet.show(context, p, cubit),
              );
            },
          ),
        const SizedBox(height: VSpacing.space3),
        Text(
          'Thay đổi chính sách không làm đổi số tồn.',
          style: TextStyle(
            fontSize: 12,
            height: 18 / 12,
            color: context.vColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
