import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/formatting/money_formatter.dart';
import '../../data/models/valuation_result_model.dart';
import '../../logic/valuation_session_cubit.dart';
import '../../logic/valuation_session_state.dart';

class ValuationResultPage extends StatelessWidget {
  const ValuationResultPage({
    super.key,
    required this.receiptId,
  });

  final String receiptId;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocBuilder<ValuationSessionCubit, ValuationSessionState>(
      builder: (context, state) {
        final result = state.lastResult;

        if (result == null) {
          return Scaffold(
            backgroundColor: colors.surface,
            appBar: const VAppBar(
              title: 'Kết quả xác lập giá trị',
              leading: SizedBox.shrink(),
            ),
            body: Center(
              child: VEmptyState(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const VEmptyHeader(
                      children: [
                        VEmptyMedia(icon: VIcons.error),
                        VEmptyTitle('Không có dữ liệu kết quả'),
                        VEmptyDescription('Vui lòng quay lại danh sách hàng chờ.'),
                      ],
                    ),
                    const VGap(VSpacing.space4),
                    VEmptyContent(
                      child: VButton(
                        label: 'Về hàng chờ',
                        variant: VButtonVariant.primary,
                        onPressed: () => context.go('/warehouse/valuation/queue'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final remaining = result.hasRemainingPending;

        return Scaffold(
          backgroundColor: colors.surface,
          appBar: const VAppBar(
            title: 'Kết quả xác lập giá trị',
            leading: SizedBox.shrink(),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  children: [
                    // Hero result
                    _HeroResultBanner(),
                    const VGap(VSpacing.space4),

                    // Flat summary rows
                    _ResultSummaryCard(result: result),
                    const VGap(VSpacing.space4),

                    // Evaluated Items
                    Text(
                      'Chi tiết mặt hàng đã ghi nhận',
                      style: VTypography.labelDefault.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const VGap(VSpacing.space2),
                    ...result.lines.map((line) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: VSpacing.space2),
                        child: _ResultLineTile(line: line),
                      );
                    }),
                    const VGap(VSpacing.space3),

                    // Remaining pending banner
                    if (remaining) ...[
                      VBanner(
                        title: 'Còn hàng chờ giá trị',
                        description:
                            '${result.remainingPendingCount} dòng chưa đủ điều kiện hoặc chưa được chọn trong lần xử lý này.',
                        tone: VComponentTone.info,
                      ),
                      const VGap(VSpacing.space3),
                    ],
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
                    label: remaining ? 'Tiếp tục xử lý' : 'Về danh sách',
                    fullWidth: true,
                    variant: VButtonVariant.primary,
                    size: VButtonSize.large,
                    onPressed: () {
                      if (remaining) {
                        context.go('/warehouse/valuation/receipt/$receiptId');
                      } else {
                        context.go('/warehouse/valuation/queue');
                      }
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

class _HeroResultBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(VSpacing.space3),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: const VIcon(
              icon: VIcons.success,
              iconSize: VIconSize.xl,
              iconColor: VIconColor.success,
            ),
          ),
          const VGap(VSpacing.space3),
          Text(
            'Đã xác lập giá trị nhập ban đầu',
            style: VTypography.headingH3.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const VGap(VSpacing.space1),
          Text(
            'Giá trị đã được ghi cho lượng hàng đã rà soát. Giá vốn sẽ được cập nhật ở công việc giá vốn.',
            style: VTypography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ResultSummaryCard extends StatelessWidget {
  const _ResultSummaryCard({required this.result});

  final ValuationResultModel result;

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
        children: [
          _SummaryRow(label: 'Phiếu nhận', value: result.receiptNumber),
          const VDivider(),
          _SummaryRow(
            label: 'Số dòng đã xác lập',
            value: '${result.lines.length}',
          ),
          const VDivider(),
          _SummaryRow(
            label: 'Tổng giá trị đã ghi',
            value: MoneyFormatter.format(amountMinor: result.totalValue.round()),
            isHighlight: true,
          ),
          const VDivider(),
          _SummaryRow(
            label: 'Giá vốn',
            value: 'Cần cập nhật',
            badgeTone: VComponentTone.warning,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.badgeTone,
  });

  final String label;
  final String value;
  final bool isHighlight;
  final VComponentTone? badgeTone;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.space2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: VTypography.bodyDefault.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (badgeTone != null)
            VBadge(
              label: value,
              tone: badgeTone!,
            )
          else
            Text(
              value,
              style: isHighlight
                  ? VTypography.headingH4.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    )
                  : VTypography.bodyDefault.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
            ),
        ],
      ),
    );
  }
}

class _ResultLineTile extends StatelessWidget {
  const _ResultLineTile({required this.line});

  final ValuationResultLine line;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    final qtyStr =
        '${line.qty.toStringAsFixed(line.qty.truncateToDouble() == line.qty ? 0 : 2)} ${line.uom}';

    return Container(
      padding: const EdgeInsets.all(VSpacing.space3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              line.productName,
              style: VTypography.bodyDefault.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$qtyStr · ${MoneyFormatter.format(amountMinor: line.totalValue.round())}',
            style: VTypography.bodyDefault.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
