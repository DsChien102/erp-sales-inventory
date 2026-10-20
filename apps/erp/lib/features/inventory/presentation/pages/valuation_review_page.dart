import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/formatting/money_formatter.dart';
import '../../data/models/valuation_cost_source.dart';
import '../../data/models/valuation_group_item.dart';
import '../../logic/valuation_session_cubit.dart';
import '../../logic/valuation_session_state.dart';

class ValuationReviewPage extends StatelessWidget {
  const ValuationReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocConsumer<ValuationSessionCubit, ValuationSessionState>(
      listener: (context, state) {
        if (state.isConfirmed) {
          context.go('/warehouse/valuation/result/${state.receiptId}');
        }
      },
      builder: (context, state) {
        final cubit = context.read<ValuationSessionCubit>();

        // Check if data is stale
        if (state.isStaleForReview) {
          return Scaffold(
            backgroundColor: colors.surface,
            appBar: const VAppBar(
              title: 'Rà soát giá trị nhập ban đầu',
            ),
            body: Padding(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                children: [
                  const VBanner(
                    title: 'Căn cứ đã thay đổi',
                    description:
                        'Kết quả rà soát cũ không còn hiệu lực. Quay lại kiểm tra căn cứ hiện hành.',
                    tone: VComponentTone.warning,
                  ),
                  const Spacer(),
                  VButton(
                    label: 'Kiểm tra lại',
                    fullWidth: true,
                    variant: VButtonVariant.primary,
                    size: VButtonSize.large,
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: colors.surface,
          appBar: const VAppBar(
            title: 'Rà soát giá trị nhập ban đầu',
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  children: [
                    // Context Row
                    _ContextRow(state: state),
                    const VGap(VSpacing.space4),

                    // Review blocks for each group
                    ...state.selectedGroups.map((group) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: VSpacing.space3),
                        child: _GroupReviewBlock(group: group),
                      );
                    }),
                    const VGap(VSpacing.space2),

                    // Total Valuation Summary Card
                    _TotalSummaryCard(totalValue: state.totalSelectedValue),
                    const VGap.cozy(),

                    // Back to edit link button
                    Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: Text(
                          'Chỉnh sửa căn cứ',
                          style: VTypography.labelDefault.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Sticky footer
              Container(
                padding: const EdgeInsets.all(VSpacing.space4),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(
                    top: BorderSide(color: colors.borderDefault),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: VButton(
                    label: state.isConfirming
                        ? 'Đang xác nhận...'
                        : 'Xác nhận giá trị',
                    fullWidth: true,
                    variant: VButtonVariant.primary,
                    size: VButtonSize.large,
                    enabled: !state.isConfirming,
                    onPressed: () {
                      cubit.confirmValuation();
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({required this.state});

  final ValuationSessionState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Container(
      padding: const EdgeInsets.all(VSpacing.space3),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            state.receiptNumber,
            style: VTypography.bodyDefault.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${state.supplierName} · ${state.receivedAt}',
            style: VTypography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupReviewBlock extends StatelessWidget {
  const _GroupReviewBlock({required this.group});

  final ValuationGroupItem group;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final source = group.selectedSource;
    final qtyStr =
        '${group.pendingQty.toStringAsFixed(group.pendingQty.truncateToDouble() == group.pendingQty ? 0 : 2)} ${group.uom}';

    return Container(
      padding: const EdgeInsets.all(VSpacing.space3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                group.productName,
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                qtyStr,
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const VGap(VSpacing.space1),
          Text(
            source?.label ?? '—',
            style: VTypography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (source != null) ...[
            const VGap(VSpacing.space2),
            _ReviewBreakdown(source: source, uom: group.uom),
          ],
          const VDivider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Giá trị sẽ ghi',
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                MoneyFormatter.format(amountMinor: group.totalValue.round()),
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewBreakdown extends StatelessWidget {
  const _ReviewBreakdown({
    required this.source,
    required this.uom,
  });

  final ValuationCostSource source;
  final String uom;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final basePrice = source.unitPrice * source.fxRate;

    return Container(
      padding: const EdgeInsets.all(VSpacing.space2),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(VRadius.r8),
      ),
      child: Column(
        children: [
          _RowItem(
            label: 'Giá mua',
            value: '${MoneyFormatter.format(amountMinor: basePrice.round())}/$uom',
          ),
          if (source.unitLineDiscount > 0)
            _RowItem(
              label: 'Chiết khấu dòng',
              value:
                  '− ${MoneyFormatter.format(amountMinor: source.unitLineDiscount.round())}/$uom',
            ),
          if (source.unitDocDiscount > 0)
            _RowItem(
              label: 'Chiết khấu chứng từ',
              value:
                  '− ${MoneyFormatter.format(amountMinor: source.unitDocDiscount.round())}/$uom',
            ),
          if (source.unitKnownCost > 0)
            _RowItem(
              label: 'Chi phí mua đã biết',
              value:
                  '+ ${MoneyFormatter.format(amountMinor: source.unitKnownCost.round())}/$uom',
            ),
          if (source.unitNonDeductibleVat > 0)
            _RowItem(
              label: 'Thuế tính vào giá trị',
              value:
                  '+ ${MoneyFormatter.format(amountMinor: source.unitNonDeductibleVat.round())}/$uom',
            ),
          _RowItem(
            label: 'Đơn giá ghi nhận ban đầu',
            value:
                '${MoneyFormatter.format(amountMinor: source.unitActual.round())}/$uom',
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: VTypography.bodySmall.copyWith(
              color: colors.textSecondary,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: VTypography.bodySmall.copyWith(
              color: colors.textPrimary,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalSummaryCard extends StatelessWidget {
  const _TotalSummaryCard({required this.totalValue});

  final double totalValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Container(
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tổng giá trị nhập ban đầu',
            style: VTypography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const VGap(VSpacing.space1),
          Text(
            MoneyFormatter.format(amountMinor: totalValue.round()),
            style: VTypography.headingH2.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
