import 'package:erp/features/inventory/logic/stock_policy/stock_policy_cubit.dart';
import 'package:erp/features/inventory/logic/stock_policy/stock_policy_rules.dart';
import 'package:erp/features/inventory/logic/stock_policy/stock_policy_state.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/k7_edit_cell.dart';
import 'package:erp/features/inventory/presentation/stock_policy/near_expiry_add_sheet.dart';
import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class NearExpiryTab extends StatelessWidget {
  final StockPolicyCubit cubit;

  const NearExpiryTab({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final state = cubit.state;
    final snapshot = state.snapshot;
    if (snapshot == null) return const SizedBox.shrink();

    final isWide = inventoryIsWide(context);
    final daysErr = defaultDaysError(state.expiryDraft.defaultDays);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Mặc định cho mọi sản phẩm',
          style: TextStyle(
            fontSize: 15,
            height: 20 / 15,
            fontWeight: FontWeight.w600,
            color: context.vColors.textPrimary,
          ),
        ),
        const SizedBox(height: VSpacing.space2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Số ngày cận hạn',
              style: TextStyle(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w600,
                color: context.vColors.textPrimary,
              ),
            ),
            const SizedBox(height: VSpacing.space1),
            K7EditCell(
              value: state.expiryDraft.defaultDays,
              enabled: !state.readOnly,
              unit: 'ngày',
              errorText: daysErr,
              semanticLabel: 'Số ngày cận hạn',
              maxWidth: isWide ? 200 : null,
              onChanged: (val) => cubit.editDefaultDays(val),
            ),
            const SizedBox(height: VSpacing.space1),
            Text(
              state.expiryDraft.defaultDays.isEmpty
                  ? 'Chưa đặt: không đánh dấu lô cận hạn.'
                  : 'Tính từ ngày hiện tại đến hạn dùng.',
              style: TextStyle(
                fontSize: 12,
                height: 18 / 12,
                color: context.vColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: VSpacing.space4),
        Text(
          'Sản phẩm có chính sách riêng',
          style: TextStyle(
            fontSize: 15,
            height: 20 / 15,
            fontWeight: FontWeight.w600,
            color: context.vColors.textPrimary,
          ),
        ),
        const SizedBox(height: VSpacing.space2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
              if (state.expiryDraft.overrides.isEmpty) ...[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: VSpacing.space2),
                  child: Text(
                    'Chưa có sản phẩm nào có chính sách riêng.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 18 / 12,
                      color: context.vColors.textSecondary,
                    ),
                  ),
                ),
              ] else ...[
                K7Table<ExpiryOverrideDraft>(
                  columns: [
                    K7Column(
                      label: 'Sản phẩm',
                      cell: (o) {
                        final p = snapshot.products
                            .where((item) => item.productId == o.productId)
                            .firstOrNull;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              p?.name ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                color: context.vColors.textPrimary,
                              ),
                            ),
                            Text(
                              p?.code ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                                color: context.vColors.textSecondary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    K7Column(
                      label: 'Số ngày',
                      numeric: true,
                      cell: (o) {
                        final p = snapshot.products
                            .where((item) => item.productId == o.productId)
                            .firstOrNull;
                        return K7EditCell(
                          value: o.days,
                          enabled: !state.readOnly,
                          unit: 'ngày',
                          errorText: overrideDaysError(o.days),
                          semanticLabel: 'Số ngày cận hạn — ${p?.name ?? ''}',
                          onChanged: (val) =>
                              cubit.editOverrideDays(o.productId, val),
                        );
                      },
                    ),
                    K7Column(
                      label: '',
                      cell: (o) => Align(
                        alignment: Alignment.centerRight,
                        child: VButton(
                          label: 'Dùng mặc định',
                          variant: VButtonVariant.tertiary,
                          onPressed: state.readOnly
                              ? null
                              : () => cubit.removeOverride(o.productId),
                        ),
                      ),
                    ),
                  ],
                  rows: state.expiryDraft.overrides,
                  mobileRow: (o) {
                    final p = snapshot.products
                        .where((item) => item.productId == o.productId)
                        .firstOrNull;
                    return VCard(
                      padding: const EdgeInsets.all(VSpacing.space3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      p?.name ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      p?.code ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.vColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!state.readOnly)
                                VButton(
                                  label: 'Dùng mặc định',
                                  variant: VButtonVariant.tertiary,
                                  onPressed: () =>
                                      cubit.removeOverride(o.productId),
                                ),
                            ],
                          ),
                          const SizedBox(height: VSpacing.space2),
                          K7EditCell(
                            value: o.days,
                            enabled: !state.readOnly,
                            unit: 'ngày',
                            errorText: overrideDaysError(o.days),
                            semanticLabel: 'Số ngày cận hạn — ${p?.name ?? ''}',
                            onChanged: (val) =>
                                cubit.editOverrideDays(o.productId, val),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: VSpacing.space2),
              ],
              if (!state.readOnly) ...[
                const SizedBox(height: VSpacing.space2),
                Align(
                  alignment: isWide ? Alignment.centerLeft : Alignment.center,
                  child: VButton(
                    label: 'Thêm sản phẩm',
                    variant: VButtonVariant.secondary,
                    fullWidth: !isWide,
                    onPressed: () => NearExpiryAddSheet.show(context, cubit),
                  ),
                ),
              ],
            ],
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
