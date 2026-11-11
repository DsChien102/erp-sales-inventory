import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft_cubit.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_line_rules.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_line_editor.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/widgets/receipt_line_row.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/widgets/receipt_product_search.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_footer.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';

class ReceiptLinesPage extends StatelessWidget {
  const ReceiptLinesPage({
    super.key,
    required this.onContinue,
    required this.onEditLine,
  });

  final VoidCallback onContinue;
  final ValueChanged<String> onEditLine;

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ReceiptDraftCubit>();
    final state = cubit.state;
    final lines = state.draft.lines;
    final knownLots = state.options?.lots ?? const [];
    final products = state.options?.products ?? const [];
    final isWide = inventoryIsWide(context);

    // Tính số dòng chưa hoàn tất
    int unhandledCount = 0;
    for (final l in lines) {
      if (lineInvalidReason(l, knownLots: knownLots) != null) {
        unhandledCount++;
      }
    }

    String linesReason = '';
    bool canContinue = false;
    if (lines.isEmpty) {
      linesReason = 'Thêm ít nhất một mặt hàng';
    } else if (unhandledCount > 0) {
      linesReason = 'Còn $unhandledCount mặt hàng chưa xử lý';
    } else {
      canContinue = true;
    }

    final supplierName = state.draft.supplier?.name ?? '';
    final docNo = state.draft.docNo.trim();
    final subtitle = [supplierName, docNo].where((s) => s.isNotEmpty).join(' · ');

    final listContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReceiptProductSearch(
          products: products,
          onSelect: (productId, unitId) {
            final lineKey = cubit.addLine(productId, unitId);
            if (isWide) {
              cubit.selectLine(lineKey);
            } else {
              onEditLine(lineKey);
            }
          },
        ),
        const SizedBox(height: VSpacing.space3),
        if (lines.isEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: VSpacing.space6),
            child: Center(
              child: Text(
                'Chưa có mặt hàng nào. Tìm sản phẩm ở trên để thêm.',
                style: VTypography.bodyDefault,
              ),
            ),
          ),
        ] else ...[
          for (final line in lines) ...[
            ReceiptLineRow(
              line: line,
              knownLots: knownLots,
              isSelected: isWide && state.selectedLineKey == line.key,
              onTap: () {
                if (isWide) {
                  cubit.selectLine(line.key);
                } else {
                  onEditLine(line.key);
                }
              },
            ),
            const SizedBox(height: VSpacing.space2),
          ],
        ],
        const SizedBox(height: VSpacing.space4),
        InventoryReasonFooter(
          label: 'Tiếp tục',
          reason: linesReason,
          onPressed: canContinue ? onContinue : null,
        ),
      ],
    );

    if (isWide) {
      final selectedKey = state.selectedLineKey ?? lines.firstOrNull?.key;

      return VPageScaffold(
        title: 'Hàng thực nhận',
        subtitle: subtitle.isNotEmpty ? subtitle : null,
        body: Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: K7Split(
            main: SingleChildScrollView(child: listContent),
            aside: selectedKey != null
                ? Container(
                    decoration: BoxDecoration(
                      color: context.vColors.surface,
                      borderRadius: BorderRadius.circular(VRadius.r12),
                      border: Border.all(
                        color: context.vColors.borderDefault,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(VSpacing.space3),
                          child: Text(
                            'Chi tiết hàng thực nhận',
                            style: VTypography.headingH4.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const VDivider(),
                        Expanded(
                          child: ReceiptLineEditor(
                            lineKey: selectedKey,
                            onDone: () {
                              // Chuyển sang dòng chưa xong kế tiếp nếu có
                              final nextUnfinished = lines.firstWhere(
                                (l) =>
                                    l.key != selectedKey &&
                                    lineInvalidReason(l, knownLots: knownLots) !=
                                        null,
                                orElse: () => lines.first,
                              );
                              cubit.selectLine(nextUnfinished.key);
                            },
                            onDelete: () {
                              cubit.removeLine(selectedKey);
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: Text('Chọn mặt hàng bên trái để chỉnh sửa.'),
                  ),
          ),
        ),
      );
    }

    return VPageScaffold(
      title: 'Hàng thực nhận',
      subtitle: subtitle.isNotEmpty ? subtitle : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: listContent,
      ),
    );
  }
}
