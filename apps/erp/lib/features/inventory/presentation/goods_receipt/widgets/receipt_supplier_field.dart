import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';

class ReceiptSupplierField extends StatelessWidget {
  const ReceiptSupplierField({
    super.key,
    required this.suppliers,
    required this.selected,
    required this.onChanged,
    this.errorText,
  });

  final List<ReceiptSupplierOption> suppliers;
  final ReceiptSupplierOption? selected;
  final ValueChanged<ReceiptSupplierOption> onChanged;
  final String? errorText;

  void _openSupplierPicker(BuildContext context) {
    // Sắp xếp NCC vãng lai (isSystem = true) lên đầu
    final sorted = List<ReceiptSupplierOption>.from(suppliers)
      ..sort((a, b) {
        if (a.isSystem && !b.isSystem) return -1;
        if (!a.isSystem && b.isSystem) return 1;
        return a.name.compareTo(b.name);
      });

    showVAdaptiveSheet(
      context: context,
      title: 'Chọn nhà cung cấp',
      child: Builder(
        builder: (sheetContext) {
          return ListView.separated(
            shrinkWrap: true,
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const VDivider(),
            itemBuilder: (ctx, index) {
              final s = sorted[index];
              final isSelected = selected?.id == s.id;
              return VListRow(
                title: s.name,
                subtitle: s.code != null ? 'Mã: ${s.code}' : null,
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onChanged(s);
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VField(
      invalid: errorText != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const VFieldLabel('Nhà cung cấp', isRequired: true),
          const SizedBox(height: VSpacing.space1),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openSupplierPicker(context),
            child: AbsorbPointer(
              child: VTextField(
                controller: TextEditingController(
                  text: selected != null
                      ? (selected!.code != null
                          ? '${selected!.name} (${selected!.code})'
                          : selected!.name)
                      : '',
                ),
                hintText: 'Chọn nhà cung cấp',
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: VSpacing.space1),
            VFieldError(errorText!),
          ],
        ],
      ),
    );
  }
}
