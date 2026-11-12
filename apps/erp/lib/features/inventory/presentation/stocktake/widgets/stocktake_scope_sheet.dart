import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Sheet chọn sản phẩm hoặc lô cụ thể khi mở phiên kiểm kê (SCR-043).
/// Trả id đã chọn (`product.id` hoặc `lot.id`), hoặc `null` nếu đóng.
Future<String?> showStocktakeScopeSheet(
  BuildContext context, {
  required StocktakeScopeKind kind,
  required List<StocktakeProductOption> products,
  required List<StocktakeLotOption> lots,
  String? selectedId,
}) {
  return showVAdaptiveSheet<String>(
    context: context,
    title: 'Chọn phạm vi',
    child: _StocktakeScopeSheetBody(
      kind: kind,
      products: products,
      lots: lots,
      selectedId: selectedId,
    ),
  );
}

class _ScopeChoiceItem {
  const _ScopeChoiceItem({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

class _StocktakeScopeSheetBody extends StatefulWidget {
  const _StocktakeScopeSheetBody({
    required this.kind,
    required this.products,
    required this.lots,
    this.selectedId,
  });

  final StocktakeScopeKind kind;
  final List<StocktakeProductOption> products;
  final List<StocktakeLotOption> lots;
  final String? selectedId;

  @override
  State<_StocktakeScopeSheetBody> createState() =>
      _StocktakeScopeSheetBodyState();
}

class _StocktakeScopeSheetBodyState extends State<_StocktakeScopeSheetBody> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_ScopeChoiceItem> get _items {
    if (widget.kind == StocktakeScopeKind.product) {
      return widget.products
          .map(
            (p) => _ScopeChoiceItem(
              id: p.id,
              title: p.name,
              subtitle: '${p.code} · ${p.lineCount} mặt hàng',
            ),
          )
          .toList(growable: false);
    }
    return widget.lots
        .map(
          (l) => _ScopeChoiceItem(
            id: l.id,
            title: '${l.productName} · Lô ${l.lotCode}',
            subtitle: l.code,
          ),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final normalized = VTextNormalizer.normalizeForSearch(_query.trim());
    final filtered = _items.where((item) {
      if (normalized.isEmpty) return true;
      final hay = VTextNormalizer.normalizeForSearch(
        '${item.title} ${item.subtitle}',
      );
      return hay.contains(normalized);
    }).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VSearchBar(
            controller: _searchController,
            hintText: 'Tìm kiếm',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: VSpacing.space3),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: VSpacing.space4),
              child: InventoryEmpty(
                title: 'Không tìm thấy phạm vi',
                description: 'Thử từ khóa khác.',
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: VSpacing.space2),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return VListRow(
                    title: item.title,
                    subtitle: item.subtitle,
                    trailing: item.id == widget.selectedId
                        ? Icon(
                            Icons.check,
                            color: context.vColors.textBrand,
                            size: 20,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(item.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

