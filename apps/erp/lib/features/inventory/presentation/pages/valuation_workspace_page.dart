import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/formatting/money_formatter.dart';
import '../../data/models/valuation_cost_source.dart';
import '../../data/models/valuation_group_item.dart';
import '../../logic/valuation_session_cubit.dart';
import '../../logic/valuation_session_state.dart';
import '../widgets/valuation_direct_basis_sheet.dart';

class ValuationWorkspacePage extends StatefulWidget {
  const ValuationWorkspacePage({
    super.key,
    required this.receiptId,
  });

  final String receiptId;

  @override
  State<ValuationWorkspacePage> createState() => _ValuationWorkspacePageState();
}

class _ValuationWorkspacePageState extends State<ValuationWorkspacePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ValuationSessionCubit>().loadReceipt(widget.receiptId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocBuilder<ValuationSessionCubit, ValuationSessionState>(
      builder: (context, state) {
        final cubit = context.read<ValuationSessionCubit>();

        return Scaffold(
          backgroundColor: colors.surface,
          appBar: const VAppBar(
            title: 'Xác lập giá trị nhập ban đầu',
          ),
          body: Builder(
            builder: (context) {
              if (state.isLoading) {
                return const Center(child: VLoading());
              }

              if (state.status == ValuationSessionStatus.failure) {
                return Center(
                  child: VEmptyState(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VEmptyHeader(
                          children: [
                            const VEmptyMedia(icon: VIcons.error),
                            const VEmptyTitle('Lỗi tải dữ liệu'),
                            VEmptyDescription(
                              state.errorMessage ?? 'Không thể tải phiếu nhận',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(VSpacing.space4),
                      children: [
                        // Context Card
                        _ReceiptContextCard(state: state),
                        const VGap(VSpacing.space4),

                        // Section Title
                        Text(
                          'Hàng chờ giá trị',
                          style: VTypography.headingH4.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const VGap(VSpacing.space2),

                        // Group Items
                        ...state.pendingGroups.map((group) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: VSpacing.space3),
                            child: _ValuationGroupCard(
                              group: group,
                              onToggleSelect: () {
                                cubit.toggleGroupSelection(group.id);
                              },
                              onAddBasis: () async {
                                final draft = await ValuationDirectBasisSheet.show(
                                  context,
                                  productName: group.productName,
                                  uom: group.uom,
                                );
                                if (draft != null) {
                                  await cubit.addDirectBasis(group.id, draft);
                                }
                              },
                            ),
                          );
                        }),

                        // Selection Summary
                        if (state.selectedGroups.isNotEmpty) ...[
                          const VGap(VSpacing.space2),
                          _SelectionSummaryCard(state: state),
                        ],
                      ],
                    ),
                  ),

                  // Sticky Footer
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
                        label: 'Rà soát',
                        fullWidth: true,
                        variant: VButtonVariant.primary,
                        size: VButtonSize.large,
                        onPressed: state.canReview
                            ? () {
                                cubit.prepareReview();
                                context.push('/warehouse/valuation/review');
                              }
                            : null,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ReceiptContextCard extends StatelessWidget {
  const _ReceiptContextCard({required this.state});

  final ValuationSessionState state;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.receiptNumber,
                  style: VTypography.headingH4.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const VGap(VSpacing.space1),
                Text(
                  '${state.supplierName} · ${state.receivedAt}',
                  style: VTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          VBadge(
            label: state.entryType.label,
            tone: VComponentTone.neutral,
          ),
        ],
      ),
    );
  }
}

class _ValuationGroupCard extends StatelessWidget {
  const _ValuationGroupCard({
    required this.group,
    required this.onToggleSelect,
    required this.onAddBasis,
  });

  final ValuationGroupItem group;
  final VoidCallback onToggleSelect;
  final VoidCallback onAddBasis;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    final lotInfo = group.tracking == 'LOT' && group.lotsCount > 0
        ? ' · ${group.lotsCount} lô'
        : '';
    final qtyInfo = '${group.pendingQty.toStringAsFixed(group.pendingQty.truncateToDouble() == group.pendingQty ? 0 : 2)} ${group.uom} đang chờ$lotInfo';

    if (group.status == ValuationGroupStatus.ready) {
      final source = group.selectedSource;
      final unitActual = group.unitActual ?? 0.0;
      final basisLabel = source?.label ?? 'Chưa có căn cứ';

      return Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(VRadius.card),
          border: Border.all(
            color: group.isSelected ? colors.primary : colors.borderDefault,
            width: group.isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onToggleSelect,
              borderRadius: BorderRadius.circular(VRadius.card),
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.space3),
                child: Row(
                  children: [
                    VCheckbox(
                      value: group.isSelected,
                      onChanged: (_) => onToggleSelect(),
                    ),
                    const VGap(VSpacing.space2, axis: Axis.horizontal),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.productName,
                            style: VTypography.bodyDefault.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const VGap(VSpacing.space1),
                          Text(
                            '$qtyInfo · $basisLabel',
                            style: VTypography.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${MoneyFormatter.format(amountMinor: unitActual.round())}/${group.uom}',
                      style: VTypography.bodyDefault.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (group.isSelected && source != null) ...[
              const VDivider(),
              Padding(
                padding: const EdgeInsets.all(VSpacing.space3),
                child: _BreakdownDetails(source: source, uom: group.uom),
              ),
            ],
          ],
        ),
      );
    }

    if (group.status == ValuationGroupStatus.commercialConflict) {
      return Container(
        padding: const EdgeInsets.all(VSpacing.space3),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(VRadius.card),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    group.productName,
                    style: VTypography.bodyDefault.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const VBadge(
                  label: 'Cần đối chiếu',
                  tone: VComponentTone.warning,
                ),
              ],
            ),
            const VGap(VSpacing.space1),
            Text(
              qtyInfo,
              style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
            ),
            const VGap(VSpacing.space2),
            const VBanner(
              title: 'Căn cứ mua hàng đang mâu thuẫn',
              description:
                  'Đối chiếu chứng từ mua có thẩm quyền trước khi xác lập giá trị.',
              tone: VComponentTone.warning,
            ),
          ],
        ),
      );
    }

    if (group.status == ValuationGroupStatus.commercialMissing) {
      return Container(
        padding: const EdgeInsets.all(VSpacing.space3),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(VRadius.card),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    group.productName,
                    style: VTypography.bodyDefault.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const VBadge(
                  label: 'Cần căn cứ',
                  tone: VComponentTone.neutral,
                ),
              ],
            ),
            const VGap(VSpacing.space1),
            Text(
              qtyInfo,
              style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
            ),
            const VGap(VSpacing.space2),
            const VBanner(
              title: 'Chưa đủ căn cứ mua hàng',
              description:
                  'Dòng nhận theo chứng từ chưa có căn cứ giá đủ điều kiện. Công việc sẽ cập nhật khi căn cứ mua hàng được bổ sung.',
              tone: VComponentTone.warning,
            ),
          ],
        ),
      );
    }

    // Direct Missing
    return Container(
      padding: const EdgeInsets.all(VSpacing.space3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  group.productName,
                  style: VTypography.bodyDefault.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const VBadge(
                label: 'Chưa có căn cứ',
                tone: VComponentTone.neutral,
              ),
            ],
          ),
          const VGap(VSpacing.space1),
          Text(
            qtyInfo,
            style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const VGap(VSpacing.space2),
          Text(
            'Nhập nhanh không cần chờ chứng từ mua. Kế toán có thể lập căn cứ giá trực tiếp và lưu dấu vết.',
            style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const VGap(VSpacing.space2),
          VButton(
            label: 'Thêm căn cứ giá',
            variant: VButtonVariant.secondary,
            size: VButtonSize.small,
            onPressed: onAddBasis,
          ),
        ],
      ),
    );
  }
}

class _BreakdownDetails extends StatelessWidget {
  const _BreakdownDetails({
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
      padding: const EdgeInsets.all(VSpacing.space3),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(VRadius.r8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Căn cứ & Cấu thành giá',
            style: VTypography.labelDefault.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const VGap(VSpacing.space2),
          _KeyValueRow(
            label: 'Nguồn',
            value: source.label,
          ),
          _KeyValueRow(
            label: 'Giá mua',
            value: '${MoneyFormatter.format(amountMinor: basePrice.round())}/$uom',
          ),
          if (source.unitLineDiscount > 0)
            _KeyValueRow(
              label: 'Chiết khấu dòng',
              value:
                  '− ${MoneyFormatter.format(amountMinor: source.unitLineDiscount.round())}/$uom',
            ),
          if (source.unitDocDiscount > 0)
            _KeyValueRow(
              label: 'Chiết khấu chứng từ',
              value:
                  '− ${MoneyFormatter.format(amountMinor: source.unitDocDiscount.round())}/$uom',
            ),
          if (source.unitKnownCost > 0)
            _KeyValueRow(
              label: 'Chi phí mua đã biết',
              value:
                  '+ ${MoneyFormatter.format(amountMinor: source.unitKnownCost.round())}/$uom',
            ),
          if (source.unitNonDeductibleVat > 0)
            _KeyValueRow(
              label: 'Thuế tính vào giá trị',
              value:
                  '+ ${MoneyFormatter.format(amountMinor: source.unitNonDeductibleVat.round())}/$uom',
            ),
          const VDivider(),
          _KeyValueRow(
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

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
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
      padding: const EdgeInsets.symmetric(vertical: VSpacing.space1),
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
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionSummaryCard extends StatelessWidget {
  const _SelectionSummaryCard({required this.state});

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
            'Đã chọn ${state.selectedGroups.length} dòng',
            style: VTypography.bodyDefault.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            MoneyFormatter.format(amountMinor: state.totalSelectedValue.round()),
            style: VTypography.headingH4.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
