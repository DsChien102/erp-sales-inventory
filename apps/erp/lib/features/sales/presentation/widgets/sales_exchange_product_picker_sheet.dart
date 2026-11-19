import 'dart:async';

import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import '../models/shared/sales_sellable_product_vm.dart';
import 'package:erp/core/formatting/money_formatter.dart';
/// O-01 — Sheet Chọn hàng đổi. Kết quả Catalog qua [searchProducts] (không demo).
Future<SalesProductSelection?> showSalesExchangeProductPickerSheet(
  BuildContext context, {
  required Future<List<SalesProductSelection>> Function(String query) searchProducts,
}) {
  return showVBottomSheet<SalesProductSelection>(
    context: context,
    title: 'Chọn hàng đổi',
    semanticLabel: 'Chọn hàng đổi',
    child: _SalesExchangeProductPickerSheetBody(
      searchProducts: searchProducts,
    ),
  );
}

enum _PickerLoadStatus { loading, ready, empty, error }

class _SalesExchangeProductPickerSheetBody extends StatefulWidget {
  const _SalesExchangeProductPickerSheetBody({
    required this.searchProducts,
  });

  final Future<List<SalesProductSelection>> Function(String query) searchProducts;

  @override
  State<_SalesExchangeProductPickerSheetBody> createState() =>
      _SalesExchangeProductPickerSheetBodyState();
}

class _SalesExchangeProductPickerSheetBodyState
    extends State<_SalesExchangeProductPickerSheetBody> {
  late final TextEditingController _searchCtrl;
  Timer? _debounce;
  int _searchGeneration = 0;
  _PickerLoadStatus _status = _PickerLoadStatus.loading;
  List<SalesProductSelection> _items = const [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    unawaited(_runSearch(''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_runSearch(value));
    });
  }

  Future<void> _runSearch(String query) async {
    final generation = ++_searchGeneration;
    setState(() {
      _status = _PickerLoadStatus.loading;
      _errorMessage = null;
    });
    try {
      final results = await widget.searchProducts(query.trim());
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _items = results;
        _status = results.isEmpty ? _PickerLoadStatus.empty : _PickerLoadStatus.ready;
      });
    } catch (error) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _items = const [];
        _status = _PickerLoadStatus.error;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return SizedBox(
      height: 480,
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VText(
              'Chạm sản phẩm để thêm vào phiếu.',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
            const VGap.sm(),
            VSearchBar(
              key: const Key('input_exchange_product_search'),
              controller: _searchCtrl,
              hintText: 'Tìm tên, SKU hoặc barcode',
              onChanged: _onQueryChanged,
            ),
            const VGap.md(),
            Expanded(child: _buildResults(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final colors = context.vColors;
    switch (_status) {
      case _PickerLoadStatus.loading:
        return _buildLoadingSkeleton(colors);
      case _PickerLoadStatus.empty:
        return const Center(
          child: VEmptyState(
            key: Key('wgt_exchange_picker_empty'),
            child: VEmptyHeader(
              children: [
                VEmptyMedia(iconData: Icons.search_off_outlined),
                VEmptyTitle('Không tìm thấy sản phẩm'),
                VEmptyDescription('Thử tìm kiếm với từ khóa khác'),
              ],
            ),
          ),
        );
      case _PickerLoadStatus.error:
        return Center(
          child: VEmptyState(
            key: const Key('wgt_exchange_picker_error'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VEmptyHeader(
                  children: [
                    const VEmptyMedia(iconData: Icons.error_outline),
                    const VEmptyTitle('Không thể tải sản phẩm'),
                    VEmptyDescription(
                      _errorMessage ?? 'Kiểm tra kết nối và thử lại.',
                    ),
                  ],
                ),
                VEmptyContent(
                  child: VButton(
                    label: 'Thử lại',
                    onPressed: () => unawaited(_runSearch(_searchCtrl.text)),
                  ),
                ),
              ],
            ),
          ),
        );
      case _PickerLoadStatus.ready:
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.borderDefault),
            borderRadius: BorderRadius.circular(VRadius.card),
          ),
          padding: const EdgeInsets.all(VSpacing.space2),
          child: ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, _) => const VGap.sm(),
            itemBuilder: (context, index) {
              final item = _items[index];
              final stock = item.stockQuantity;
              final isLowStock = stock != null && stock > 0 && stock <= 5;
              final stockLabel = isLowStock
                  ? 'Còn $stock'
                  : (stock?.toString() ?? '');

              return VCard(
                key: Key('btn_select_exchange_${item.productUnitId}'),
                onTap: () => Navigator.of(context).pop(item),
                backgroundColor: colors.surface,
                border: Border.all(color: colors.borderDefault),
                padding: const EdgeInsets.all(VSpacing.space3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        borderRadius: BorderRadius.circular(VRadius.r8),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        color: colors.textMuted,
                        size: 24,
                      ),
                    ),
                    const VGap.horizontalMd(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VText(
                            item.productName,
                            variant: VTextVariant.bodyDefault,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                          ),
                          const VGap.xs(),
                          VText(
                            '${item.productName} · ${item.unitLabel}',
                            variant: VTextVariant.bodySmall,
                            color: colors.textSecondary,
                            maxLines: 1,
                          ),
                          const VGap.sm(),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: VText(
                                  MoneyFormatter.format(amountMinor: item.unitPrice.amountMinor, currencyCode: item.unitPrice.currencyCode),
                                  variant: VTextVariant.bodyDefault,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: VText(
                                  item.unitLabel,
                                  variant: VTextVariant.bodySmall,
                                  color: colors.textSecondary,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: VText(
                                  stockLabel,
                                  variant: VTextVariant.bodySmall,
                                  color: isLowStock ? colors.warning : colors.textSecondary,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
    }
  }

  Widget _buildLoadingSkeleton(dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(VRadius.card),
      ),
      padding: const EdgeInsets.all(VSpacing.space2),
      child: VSkeletonScope(
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (_, _) => const VGap.sm(),
          itemBuilder: (_, _) {
            return VCard(
              backgroundColor: colors.surface,
              border: Border.all(color: colors.borderDefault),
              padding: const EdgeInsets.all(VSpacing.space3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VSkeleton(
                    width: 48,
                    height: 48,
                    borderRadius: VRadius.r8,
                  ),
                  const VGap.horizontalMd(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const VSkeleton(
                          width: 140,
                          height: 16,
                          borderRadius: VRadius.r4,
                        ),
                        const VGap.xs(),
                        const VSkeleton(
                          width: 180,
                          height: 12,
                          borderRadius: VRadius.r4,
                        ),
                        const VGap.sm(),
                        Row(
                          children: const [
                            Expanded(
                              flex: 3,
                              child: VSkeleton(
                                width: 80,
                                height: 16,
                                borderRadius: VRadius.r4,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: VSkeleton(
                                  width: 40,
                                  height: 12,
                                  borderRadius: VRadius.r4,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: VSkeleton(
                                  width: 30,
                                  height: 12,
                                  borderRadius: VRadius.r4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
