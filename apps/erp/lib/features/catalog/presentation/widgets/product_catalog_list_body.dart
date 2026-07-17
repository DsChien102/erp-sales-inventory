import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

import 'product_list_filter.dart';

class ProductCatalogListBody extends StatelessWidget {
  const ProductCatalogListBody({
    super.key,
    required this.scrollController,
    required this.selectedFilter,
    required this.globalTotalCount,
    required this.onRefresh,
    required this.onTapItem,
    required this.onCreateProduct,
  });

  /// Viewport-friendly skeleton count for first load / refresh (option B).
  static const int firstLoadSkeletonCount = 8;

  final ScrollController scrollController;
  final ProductListFilter selectedFilter;
  final int? globalTotalCount;
  final Future<void> Function() onRefresh;
  final ValueChanged<ProductListItemDto> onTapItem;
  final Future<void> Function() onCreateProduct;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocBuilder<ProductListCubit, ProductListState>(
      builder: (context, state) {
        if (state is ProductListInitial ||
            (state is ProductListLoading && state.isFirstLoad)) {
          return VSkeletonScope(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.only(
                left: VSpacing.screenMobile,
                right: VSpacing.screenMobile,
                bottom: VSpacing.space2,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: firstLoadSkeletonCount,
              itemBuilder: (context, index) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: VSpacing.sm),
                  child: ProductListItemSkeletonTile(),
                );
              },
            ),
          );
        }

        if (state is ProductListError) {
          return Center(
            child: VText(
              'Lỗi: ${state.message}',
              variant: VTextVariant.bodyDefault,
              color: dynamicColors.danger,
              textAlign: TextAlign.center,
            ),
          );
        }

        var items = state is ProductListLoaded ? state.items : (state as ProductListLoading).items;

        if (selectedFilter == ProductListFilter.inStock) {
          items = items.where((item) => (item.stockQuantity ?? 0) > 0).toList();
        } else if (selectedFilter == ProductListFilter.outOfStock) {
          items = items.where((item) => (item.stockQuantity ?? 0) == 0).toList();
        }

        if (items.isEmpty && state is! ProductListLoading) {
          return _ProductCatalogEmptyState(
            selectedFilter: selectedFilter,
            hasProducts: (globalTotalCount ?? 0) > 0,
            onCreateProduct: onCreateProduct,
          );
        }

        final isLoadingMore = state is ProductListLoading && !state.isFirstLoad;
        final hasReachedMax = state is ProductListLoaded && state.hasReachedMax;

        final int trailingCount;
        if (isLoadingMore) {
          trailingCount = ProductListCubit.pageSize;
        } else if (hasReachedMax && items.isNotEmpty) {
          trailingCount = 1;
        } else {
          trailingCount = 0;
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          displacement: VSpacing.space2,
          child: VSkeletonScope(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.only(
                left: VSpacing.screenMobile,
                right: VSpacing.screenMobile,
                bottom: VSpacing.space2,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length + trailingCount,
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  if (isLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: VSpacing.sm),
                      child: ProductListItemSkeletonTile(),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: VSpacing.md),
                    child: Center(
                      child: VText(
                        'Đã ở cuối danh sách',
                        variant: VTextVariant.bodySmall,
                        color: dynamicColors.textSecondary,
                      ),
                    ),
                  );
                }

                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: VSpacing.sm),
                  child: ProductListItemTile(
                    item: item,
                    onTap: () => onTapItem(item),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ProductCatalogEmptyState extends StatelessWidget {
  const _ProductCatalogEmptyState({
    required this.selectedFilter,
    required this.hasProducts,
    required this.onCreateProduct,
  });

  final ProductListFilter selectedFilter;
  final bool hasProducts;
  final Future<void> Function() onCreateProduct;

  @override
  Widget build(BuildContext context) {
    final isFiltered = selectedFilter != ProductListFilter.all;

    final String title;
    final String? description;
    final String? actionLabel;
    final Future<void> Function()? onActionPressed;

    if (!hasProducts) {
      title = 'Chưa có sản phẩm nào được tạo';
      description = null;
      actionLabel = 'Tạo sản phẩm';
      onActionPressed = onCreateProduct;
    } else {
      title = isFiltered
          ? 'Không tìm thấy sản phẩm "${selectedFilter.label}"'
          : 'Không tìm thấy sản phẩm';
      description = 'Hãy thử tìm kiếm với từ khóa khác hoặc tạo sản phẩm mới.';
      actionLabel = null;
      onActionPressed = null;
    }

    return Center(
      child: VEmptyState(
        icon: VIcons.inventory,
        title: title,
        description: description,
        actionLabel: actionLabel,
        actionLeadingIcon: actionLabel != null ? const VIcon(icon: VIcons.add, size: 18) : null,
        onActionPressed: onActionPressed,
      ),
    );
  }
}
