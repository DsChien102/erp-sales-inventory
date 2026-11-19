import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_cost_rules.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft_cubit.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft_state.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_line_rules.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/widgets/receipt_allocation_block.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/widgets/receipt_line_sheet.dart';

class ReceiptReviewPage extends StatelessWidget {
  const ReceiptReviewPage({
    super.key,
    required this.onSuccess,
  });

  final ValueChanged<RecordReceiptResult> onSuccess;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReceiptDraftCubit, ReceiptDraftState>(
      listenWhen: (previous, current) => previous.result != current.result && current.result != null,
      listener: (context, state) {
        if (state.result != null) {
          onSuccess(state.result!);
        }
      },
      builder: (context, state) {
        final cubit = context.read<ReceiptDraftCubit>();
        final supplier = state.draft.supplier;
        final docNo = state.draft.docNo.trim();
        final subtitle = '${supplier?.name ?? ''} · ${docNo.isEmpty ? '(Chưa có số HĐ)' : docNo}';

        final attentions = reviewAttention(state.draft.lines);

        final costInputs = state.draft.lines.map((l) {
          return ReceiptCostLineInput(
            paidQty: l.paidQuantity,
            freeQty: l.freeQty,
            rate: l.unit.rate,
            unitPriceVnd: l.unitPriceVnd,
            tierPercent: l.tierPercent,
            lotQuantities: l.lots.map((lot) => lot.quantity).toList(),
          );
        }).toList();

        final breakdown = computeReceiptCost(
          costInputs,
          freightVnd: state.draft.freightVnd,
          discountVnd: state.draft.discountVnd,
        );

        return VPageScaffold(
          title: 'Rà soát nhận hàng',
          subtitle: subtitle,
          contentMaxWidth: const VResponsiveValue(
            mobile: double.infinity,
            tablet: 900,
            desktop: 1200,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Attention banners
                for (final att in attentions) ...[
                  VBanner(
                    tone: att.tone,
                    title: att.title,
                    description: att.message,
                  ),
                  const SizedBox(height: VSpacing.space2),
                ],

                // 2. Network / submit error banner
                if (state.submitNetworkError) ...[
                  VBanner(
                    tone: VComponentTone.danger,
                    title: 'Chưa ghi nhận được do mất kết nối.',
                    footer: Padding(
                      padding: const EdgeInsets.only(top: VSpacing.space1),
                      child: VButton(
                        label: 'Thử lại',
                        size: VButtonSize.small,
                        onPressed: cubit.submit,
                      ),
                    ),
                  ),
                  const SizedBox(height: VSpacing.space2),
                ] else if (state.submitError != null) ...[
                  VBanner(
                    tone: VComponentTone.danger,
                    title: inventoryErrorMessage(
                      AppException(state.submitError!),
                      fallback: state.submitError!,
                    ),
                  ),
                  const SizedBox(height: VSpacing.space2),
                ],

                // 3. Hàng thực nhận
                Text(
                  'Hàng thực nhận (${state.draft.lines.length})',
                  style: VTypography.headingH4,
                ),
                const SizedBox(height: VSpacing.space2),
                for (final line in state.draft.lines) ...[
                  VCard(
                    onTap: () => showReceiptLineDetailSheet(
                      context: context,
                      line: line,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.product.name,
                                style: VTypography.labelDefault,
                              ),
                              const SizedBox(height: VSpacing.space1),
                              Text(
                                '${line.totalQuantity} ${line.unit.name} · ${line.lots.length} lô',
                                style: VTypography.bodySmall,
                              ),
                              if (offerSummary(line) != null) ...[
                                const SizedBox(height: VSpacing.space1),
                                Text(
                                  offerSummary(line)!,
                                  style: VTypography.bodySmall.copyWith(
                                    color: context.vColors.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: VSpacing.space2),
                ],

                const SizedBox(height: VSpacing.space4),

                // 4. Chi phí & Chiết khấu
                Text('Chi phí & Chiết khấu', style: VTypography.headingH4),
                const SizedBox(height: VSpacing.space2),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chi phí thu mua', style: VTypography.labelDefault),
                          const SizedBox(height: VSpacing.space1),
                          VNumberField(
                            key: const Key('receipt_freight_cost'),
                            value: state.draft.freightVnd,
                            suffixText: 'đ',
                            onChanged: (val) => cubit.setFreightVnd((val ?? 0).toInt()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: VSpacing.space2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chiết khấu thương mại', style: VTypography.labelDefault),
                          const SizedBox(height: VSpacing.space1),
                          VNumberField(
                            key: const Key('receipt_trade_discount'),
                            value: state.draft.discountVnd,
                            suffixText: 'đ',
                            onChanged: (val) => cubit.setDiscountVnd((val ?? 0).toInt()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: VSpacing.space4),

                // 5. Khối Phân bổ giá gốc
                Text('Phân bổ giá gốc', style: VTypography.headingH4),
                const SizedBox(height: VSpacing.space2),
                ReceiptAllocationBlock(
                  lines: state.draft.lines,
                  freightVnd: state.draft.freightVnd,
                  discountVnd: state.draft.discountVnd,
                ),

                const SizedBox(height: VSpacing.space6),

                // 6. Nút Ghi nhận
                VButton(
                  label: 'Ghi nhận',
                  size: VButtonSize.large,
                  isLoading: state.submit == ReceiptSubmitStatus.submitting,
                  onPressed: (breakdown.discountTooLarge || state.draft.lines.isEmpty)
                      ? null
                      : cubit.submit,
                ),
                const SizedBox(height: VSpacing.space8),
              ],
            ),
          ),
        );
      },
    );
  }
}
