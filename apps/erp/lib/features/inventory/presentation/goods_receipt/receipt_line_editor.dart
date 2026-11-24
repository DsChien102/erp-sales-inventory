import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft_cubit.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_line_rules.dart';
import 'package:erp/features/inventory/logic/inventory_format.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/widgets/receipt_lot_list.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/widgets/receipt_offer_block.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';

class ReceiptLineEditor extends StatelessWidget {
  const ReceiptLineEditor({
    super.key,
    required this.lineKey,
    required this.onDone,
    this.onDelete,
    this.onCompareSuppliers,
  });

  final String lineKey;
  final VoidCallback onDone;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onCompareSuppliers;

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ReceiptDraftCubit>();
    final state = cubit.state;

    final line = state.draft.lines.where((l) => l.key == lineKey).firstOrNull;
    if (line == null) {
      return const Center(
        child: Text('Chưa chọn sản phẩm cần xử lý.'),
      );
    }

    final knownLots = state.options?.lots ?? const [];
    final invalidReason = lineInvalidReason(line, knownLots: knownLots);
    final canSave = invalidReason == null;

    // Tính thành tiền a_i = gross - tierDiscount
    final gross = (line.paidQuantity * line.unitPriceVnd).round();
    final tier = line.tierPercent != null
        ? (gross * line.tierPercent! / 100.0).round()
        : 0;
    final purchase = gross - tier;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Tóm tắt sản phẩm
          VCard(
            child: Padding(
              padding: const EdgeInsets.all(VSpacing.space3),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 28),
                  const SizedBox(width: VSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.product.name,
                          style: VTypography.bodyDefault.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${line.product.code} · ${line.unit.name}',
                          style: VTypography.bodySmall,
                        ),
                        if (onCompareSuppliers != null &&
                            line.product.id.isNotEmpty) ...[
                          const SizedBox(height: VSpacing.space1),
                          VButton(
                            variant: VButtonVariant.link,
                            size: VButtonSize.small,
                            label: 'So sánh nhà cung cấp',
                            onPressed: () =>
                                onCompareSuppliers!(line.product.id),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const VChip(label: 'Đã chọn'),
                ],
              ),
            ),
          ),
          const SizedBox(height: VSpacing.space4),

          // 2. Lô thực nhận
          ReceiptLotList(
            key: ValueKey('lot_list_${line.key}'),
            line: line,
            knownLots: knownLots,
            onChanged: (updated) {
              cubit.updateLine(lineKey, (_) => updated);
            },
          ),
          const SizedBox(height: VSpacing.space4),

          // 3. Giá mua / ĐVT
          VField(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VFieldLabel('Giá mua / ${line.unit.name}', isRequired: true),
                const SizedBox(height: VSpacing.space1),
                VMoneyField(
                  key: const Key('receipt_unit_price'),
                  value: line.unitPriceVnd > 0 ? line.unitPriceVnd : null,
                  suffixText: 'đ',
                  onChanged: (val) {
                    cubit.updateLine(
                      lineKey,
                      (l) => l.copyWith(unitPriceVnd: val ?? 0),
                    );
                  },
                ),
                const SizedBox(height: VSpacing.space1),
                const VFieldDescription('Theo hoá đơn, đã gồm VAT.'),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.space4),

          // 4. Khối ưu đãi NCC
          ReceiptOfferBlock(
            line: line,
            hintsLoading: state.hintsLoading,
            onChanged: (updated) {
              cubit.updateLine(lineKey, (_) => updated);
            },
          ),
          const SizedBox(height: VSpacing.space4),

          // 5. Tổng nhận & Thành tiền
          VCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: VSpacing.space2),
              child: Column(
                children: [
                  VKeyValueRow(
                    label: 'Tổng nhận',
                    value:
                        '${formatQuantity(line.totalQuantity.toDouble())} ${line.unit.name}',
                    mono: true,
                  ),
                  VKeyValueRow(
                    label: 'Thành tiền',
                    value: MoneyFormatter.formatMinor(purchase),
                    emphasized: true,
                    mono: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: VSpacing.space4),

          // 6. Xóa khỏi lần nhận
          if (onDelete != null) ...[
            Align(
              alignment: Alignment.center,
              child: VButton(
                variant: VButtonVariant.link,
                tone: VComponentTone.danger,
                label: 'Xóa khỏi lần nhận',
                onPressed: onDelete,
              ),
            ),
            const SizedBox(height: VSpacing.space4),
          ],

          // 7. Chân trang
          InventoryReasonFooter(
            label: 'Xong',
            reason: invalidReason ?? '',
            onPressed: canSave ? onDone : null,
          ),
        ],
      ),
    );
  }
}
