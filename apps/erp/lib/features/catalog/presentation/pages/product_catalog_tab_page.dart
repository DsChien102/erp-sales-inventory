import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_shared_application/application.dart';

import 'product_control_center_page.dart';

class ProductCatalogTabPage extends StatefulWidget {
  const ProductCatalogTabPage({super.key});

  @override
  State<ProductCatalogTabPage> createState() => _ProductCatalogTabPageState();
}

enum ProductListFilter {
  all('Tất cả'),
  readyToSell('Sẵn sàng bán'),
  incomplete('Thiếu dữ liệu'),
  inactive('Ngừng KD'),
  inStock('Còn hàng'),
  outOfStock('Hết hàng'),
  negativeStock('Tồn âm');

  final String label;
  const ProductListFilter(this.label);
}

class _ProductCatalogTabPageState extends State<ProductCatalogTabPage> {
  final ScrollController _scrollController = ScrollController();
  late final ProductListCubit _cubit;
  ProductListFilter _selectedFilter = ProductListFilter.all;

  @override
  void initState() {
    super.initState();
    _cubit = ProductListCubit(
      mediator: GetIt.instance<ICatalogModule>(),
      executionContext: GetIt.instance<IExecutionContext>(),
    )..fetchProducts();

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _cubit.fetchProducts();
    }
  }

  void _onSearch(String query) {
    _cubit.searchByKeyword(query);
  }

  void _onFilterChanged(ProductListFilter filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
    });
    
    final keyword = _cubit.state is ProductListLoaded
        ? (_cubit.state as ProductListLoaded).criteria.keyword
        : null;

    ProductSearchCriteria newCriteria;
    switch (filter) {
      case ProductListFilter.readyToSell:
        newCriteria = ProductSearchCriteria(keyword: keyword, readinessFilter: ProductReadinessFilter.readyToSell);
        break;
      case ProductListFilter.incomplete:
        newCriteria = ProductSearchCriteria(keyword: keyword, readinessFilter: ProductReadinessFilter.incomplete);
        break;
      case ProductListFilter.inactive:
        newCriteria = ProductSearchCriteria(keyword: keyword, businessStatuses: {ProductStatus.inactive});
        break;
      default:
        // Stock filters and 'all' fallback to generic search, UI does local filtering for stock
        newCriteria = ProductSearchCriteria(keyword: keyword);
        break;
    }
    _cubit.fetchProducts(criteria: newCriteria, isRefresh: true);
  }

  Widget _buildFilterChips(BuildContext context, dynamic dynamicColors, ProductListState state) {
    final globalCount = _cubit.globalTotalCount;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ProductListFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          String label = filter.label;
          if (filter == ProductListFilter.all && globalCount != null) {
            label = '${filter.label} ($globalCount)';
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onFilterChanged(filter),
              child: _buildChip(dynamicColors, label, isSelected),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChip(dynamic colors, String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? colors.success : colors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? null : Border.all(color: colors.borderDefault),
      ),
      child: Text(
        label,
        style: VTypography.bodySmall.copyWith(
          color: isSelected ? colors.surface : colors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  void _navigateToProduct(BuildContext context, ProductListItemDto dto) {
    final readinessStatus = dto.readinessSummary.status == ReadinessStatus.readyToSell
        ? ProductReadinessStatus.ready
        : ProductReadinessStatus.needsReview;

    final businessStatus = dto.businessStatus == ProductStatus.active 
        ? ProductBusinessStatus.active 
        : ProductBusinessStatus.inactive;

    final model = ProductListItemModel(
      id: dto.id,
      name: dto.name,
      tradeName: dto.tradeName,
      sku: dto.sku,
      barcode: dto.barcode,
      imageUrl: dto.primaryImageUrl,
      businessStatus: businessStatus,
      readinessStatus: readinessStatus,
      listPrice: dto.listPrice,
      floorPrice: dto.floorPrice,
      baseUnit: dto.baseUnit,
      stockQty: dto.stockQuantity,
      stockLabel: dto.stockLabel,
    );

    context.push(
      '/products/items/pcc',
      extra: ProductControlCenterRouteArgs(product: model),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        key: const Key('wgt_e01_u01_fr01_01'),
        backgroundColor: dynamicColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: BlocBuilder<ProductListCubit, ProductListState>(
            builder: (context, state) {
              return VAppBar(
                title: 'Sản phẩm',
                titleStyle: VTypography.headingH4.copyWith(
                  color: dynamicColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                subtitle: _cubit.globalTotalCount != null ? '${_cubit.globalTotalCount} sản phẩm' : null,
                showBackButton: false,
                actions: [
                  IconButton(
                    icon: Icon(Icons.more_vert, color: dynamicColors.textPrimary),
                    onPressed: () {},
                  ),
                ],
              );
            },
          ),
        ),
        body: Column(
          children: [
            ProductListSearchBar(onSearch: _onSearch),
            BlocBuilder<ProductListCubit, ProductListState>(
              builder: (context, state) => _buildFilterChips(context, dynamicColors, state),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<ProductListCubit, ProductListState>(
                builder: (context, state) {
                  if (state is ProductListInitial || (state is ProductListLoading && state.isFirstLoad)) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ProductListError) {
                    return Center(child: Text('Lỗi: ${state.message}'));
                  }

                  List<ProductListItemDto> items = state is ProductListLoaded
                      ? state.items
                      : (state as ProductListLoading).items;

                  // Local filtering for stock statuses
                  if (_selectedFilter == ProductListFilter.inStock) {
                    items = items.where((item) => (item.stockQuantity ?? 0) > 0).toList();
                  } else if (_selectedFilter == ProductListFilter.outOfStock) {
                    items = items.where((item) => (item.stockQuantity ?? 0) == 0).toList();
                  } else if (_selectedFilter == ProductListFilter.negativeStock) {
                    items = items.where((item) => (item.stockQuantity ?? 0) < 0).toList();
                  }

                  if (items.isEmpty && state is! ProductListLoading) {
                    return Center(
                      child: VEmptyState(
                        iconData: Icons.inventory_2_outlined,
                        title: 'Không tìm thấy sản phẩm',
                        description: 'Hãy thử tìm kiếm với từ khóa khác hoặc tạo sản phẩm mới.',
                        actionLabel: 'Tạo sản phẩm',
                        actionLeadingIcon: const Icon(Icons.add, size: 18),
                        onActionPressed: () => context.push('/products/items/new'),
                      ),
                    );
                  }

                  final hasReachedMax = state is ProductListLoaded ? state.hasReachedMax : false;

                  return RefreshIndicator(
                    onRefresh: () => _cubit.fetchProducts(isRefresh: true),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length + (hasReachedMax ? 0 : 1),
                      itemBuilder: (context, index) {
                        if (index >= items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final item = items[index];
                        return ProductListItemTile(
                          item: item,
                          onTap: () => _navigateToProduct(context, item),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: VFloatingActionButton(
          key: const Key('btn_create_product'),
          iconData: Icons.add,
          onTap: () => context.push('/products/items/new'),
          backgroundColor: dynamicColors.success,
        ),
      ),
    );
  }
}
