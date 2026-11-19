import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';

class ReceiptProductSearch extends StatelessWidget {
  const ReceiptProductSearch({
    super.key,
    required this.products,
    required this.onSelect,
  });

  final List<ReceiptProductOption> products;
  final void Function(String productId, String unitId) onSelect;

  void _openProductPicker(BuildContext context) {
    String searchQuery = '';
    showVAdaptiveSheet(
      context: context,
      title: 'Chọn sản phẩm',
      child: StatefulBuilder(
        builder: (sheetContext, setState) {
          final filtered = products.where((p) {
            if (searchQuery.isEmpty) return true;
            final q = searchQuery.toLowerCase();
            return p.name.toLowerCase().contains(q) ||
                p.code.toLowerCase().contains(q) ||
                (p.barcode != null && p.barcode!.toLowerCase().contains(q));
          }).toList();

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(VSpacing.space3),
                child: VTextField(
                  hintText: 'Tìm tên, mã sản phẩm hoặc mã vạch',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  onChanged: (val) {
                    setState(() {
                      searchQuery = val.trim();
                    });
                  },
                ),
              ),
              const VDivider(),
              Flexible(
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(VSpacing.space4),
                        child: Text(
                          'Sản phẩm chưa có trong danh mục. Hãy bổ sung sản phẩm trước khi quay lại nhận hàng.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const VDivider(),
                        itemBuilder: (c, idx) {
                          final p = filtered[idx];
                          final uomSummary =
                              p.units.map((u) => u.name).join(', ');
                          return VListRow(
                            leading: VIcons.inventory,
                            title: p.name,
                            subtitle: '${p.code} · $uomSummary',
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              // Nếu có nhiều ĐVT -> mở sheet chọn ĐVT
                              if (p.units.length > 1) {
                                _openUnitPicker(context, p);
                              } else {
                                onSelect(p.id, p.baseUnit.id);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openUnitPicker(BuildContext context, ReceiptProductOption product) {
    showVAdaptiveSheet(
      context: context,
      title: 'Chọn đơn vị nhập',
      child: Builder(
        builder: (sheetContext) {
          return ListView.separated(
            shrinkWrap: true,
            itemCount: product.units.length,
            separatorBuilder: (_, _) => const VDivider(),
            itemBuilder: (ctx, idx) {
              final u = product.units[idx];
              return VListRow(
                title: u.name,
                subtitle: u.isBase ? 'Đơn vị cơ sở' : 'Hệ số: ${u.rate}',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onSelect(product.id, u.id);
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openProductPicker(context),
      child: AbsorbPointer(
        child: VTextField(
          hintText: 'Tìm tên, mã sản phẩm hoặc mã vạch',
          prefixIcon: const Icon(Icons.search, size: 18),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
      ),
    );
  }
}
