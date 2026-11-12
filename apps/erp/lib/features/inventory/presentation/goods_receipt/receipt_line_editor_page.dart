import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft_cubit.dart';
import 'package:erp/features/inventory/presentation/goods_receipt/receipt_line_editor.dart';

class ReceiptLineEditorPage extends StatelessWidget {
  const ReceiptLineEditorPage({
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
    return VPageScaffold(
      title: 'Chi tiết hàng thực nhận',
      body: ReceiptLineEditor(
        lineKey: lineKey,
        onDone: onDone,
        onDelete: onDelete ??
            () {
              context.read<ReceiptDraftCubit>().removeLine(lineKey);
              Navigator.of(context).maybePop();
            },
        onCompareSuppliers: onCompareSuppliers ??
            (productId) => context.push(
              '/warehouse/stock/${Uri.encodeComponent(productId)}/suppliers',
            ),
      ),
    );
  }
}
