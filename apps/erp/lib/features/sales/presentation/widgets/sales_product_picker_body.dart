import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/shared/sales_product_picker_state.dart';
import '../models/shared/sales_sellable_product_vm.dart';
import 'sales_product_picker_card.dart';

class SalesProductPickerBody extends StatelessWidget {
  const SalesProductPickerBody({
    super.key,
    required this.state,
    required this.onTapProduct,
    required this.onClearSearch,
  });

  final SalesProductPickerState state;
  final ValueChanged<SalesSellableProductVm> onTapProduct;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      SalesProductPickerLoading() => const Center(child: VLoading()),
      SalesProductPickerError(:final message) => VEmptyState(
        key: const Key('wgt_sg03_product_error'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VEmptyHeader(
              children: [
                const VEmptyMedia(icon: VIcons.warning),
                const VEmptyTitle('Không thể tải sản phẩm'),
                VEmptyDescription(message),
              ],
            ),
            VEmptyContent(
              child: VButton(
                label: 'Thử lại',
                onPressed: onClearSearch,
              ),
            ),
          ],
        ),
      ),
      SalesProductPickerEmptyCatalog() => const VEmptyState(
        key: Key('wgt_sg03_empty_catalog'),
        child: VEmptyHeader(
          children: [
            VEmptyMedia(icon: VIcons.inventory),
            VEmptyTitle('Chưa có sản phẩm bán được'),
            VEmptyDescription('Quay lại đơn hàng và kiểm tra quyền / cửa hàng.'),
          ],
        ),
      ),
      SalesProductPickerNoResult(:final query) => VEmptyState(
        key: const Key('wgt_sg03_no_result'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VEmptyHeader(
              children: [
                const VEmptyMedia(icon: VIcons.search),
                const VEmptyTitle('Không tìm thấy sản phẩm'),
                VEmptyDescription('Không có kết quả cho “$query”.'),
              ],
            ),
            VEmptyContent(
              child: VButton(
                label: 'Xóa tìm kiếm',
                onPressed: onClearSearch,
              ),
            ),
          ],
        ),
      ),
      SalesProductPickerLoaded(:final items, :final query) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VPagePadding(
            child: VText(
              query.isEmpty ? '${items.length} sản phẩm' : '${items.length} sản phẩm · “$query”',
              key: const Key('txt_sg03_result_count'),
              variant: VTextVariant.bodySmall,
              color: context.vColors.textSecondary,
            ),
          ),
          const VGap.sm(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: VSpacing.space8),
              itemCount: items.length,
              separatorBuilder: (_, _) => const VGap.sm(),
              itemBuilder: (context, index) {
                final product = items[index];
                return VPagePadding(
                  child: SalesProductPickerCard(
                    product: product,
                    onTap: () => onTapProduct(product),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    };
  }
}
