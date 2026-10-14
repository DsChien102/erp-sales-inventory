import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/goods_receipt_repository.dart';

class ReceiptSupplierSelectSheet extends StatefulWidget {
  const ReceiptSupplierSelectSheet({
    super.key,
    required this.suppliers,
    this.selectedSupplierId,
  });

  final List<ReceiptSupplierDto> suppliers;
  final String? selectedSupplierId;

  static Future<ReceiptSupplierDto?> show(
    BuildContext context, {
    required List<ReceiptSupplierDto> suppliers,
    String? selectedSupplierId,
  }) {
    return showModalBottomSheet<ReceiptSupplierDto>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReceiptSupplierSelectSheet(
        suppliers: suppliers,
        selectedSupplierId: selectedSupplierId,
      ),
    );
  }

  @override
  State<ReceiptSupplierSelectSheet> createState() =>
      _ReceiptSupplierSelectSheetState();
}

class _ReceiptSupplierSelectSheetState
    extends State<ReceiptSupplierSelectSheet> {
  String _keyword = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final filtered = widget.suppliers.where((s) {
      final query = _keyword.toLowerCase();
      return s.name.toLowerCase().contains(query) ||
          s.code.toLowerCase().contains(query);
    }).toList();

    return VBottomSheet(
      title: 'Chọn nhà cung cấp',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VTextField(
              hintText: 'Tìm theo tên hoặc mã...',
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: VSpacing.space2),
                child: VIcon(
                  icon: VIcons.search,
                  iconSize: VIconSize.md,
                  iconColor: VIconColor.muted,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _keyword = val;
                });
              },
            ),
            const VGap(VSpacing.space3),
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(VSpacing.space6),
                      child: Center(
                        child: VText(
                          'Không tìm thấy nhà cung cấp',
                          style: VTypography.bodyDefault.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const VDivider(),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isSelected = item.id == widget.selectedSupplierId;
                        return InkWell(
                          onTap: () => Navigator.of(context).pop(item),
                          borderRadius: BorderRadius.circular(VRadius.button),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: VSpacing.space3,
                              horizontal: VSpacing.space2,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      VText(
                                        item.name,
                                        style: VTypography.labelDefault.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? colors.primary
                                              : colors.textPrimary,
                                        ),
                                      ),
                                      const VGap(VSpacing.space1),
                                      VText(
                                        'Mã: ${item.code}${item.phone.isNotEmpty ? " • SĐT: ${item.phone}" : ""}',
                                        style: VTypography.caption.copyWith(
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const VIcon(
                                    icon: VIcons.check,
                                    iconSize: VIconSize.md,
                                    iconColor: VIconColor.primary,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const VGap(VSpacing.space4),
          ],
        ),
      ),
    );
  }
}
