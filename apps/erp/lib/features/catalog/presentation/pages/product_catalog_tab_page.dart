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
import '../widgets/custom_field_filter_sheet.dart';
import '../widgets/product_catalog_filter_chips.dart';
import '../widgets/product_catalog_list_body.dart';
import '../widgets/product_list_filter.dart';

class ProductCatalogTabPage extends StatefulWidget {
  const ProductCatalogTabPage({super.key});

  @override
  State<ProductCatalogTabPage> createState() => _ProductCatalogTabPageState();
}

class _ProductCatalogTabPageState extends State<ProductCatalogTabPage> {
  static final Set<ProductBusinessStatus> _catalogListStatuses = {
    ProductBusinessStatus.active,
    ProductBusinessStatus.inactive,
  };

  final ScrollController _scrollController = ScrollController();
  late final ProductListCubit _cubit;
  ProductListFilter _selectedFilter = ProductListFilter.all;
  List<CustomFieldFilterCriteria> _customFieldFilters = [];
  List<CustomFieldFilterOptionDto> _filterOptions = [];

  @override
  void initState() {
    super.initState();
    _cubit =
        ProductListCubit(
          mediator: GetIt.instance<ICatalogModule>(),
          executionContext: GetIt.instance<IExecutionContext>(),
        )..fetchProducts(
          criteria: ProductSearchCriteria(businessStatuses: _catalogListStatuses),
        );

    _scrollController.addListener(_onScroll);
    _loadFilterOptions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final catalogModule = GetIt.instance<ICatalogModule>();
      final executionContext = GetIt.instance<IExecutionContext>();
      final tenantId = await executionContext.requireTenantId();
      final query = ListCustomFieldFilterOptionsQuery(tenantId: tenantId);
      final options = await catalogModule.executeQueryAsync(query);
      if (mounted) {
        setState(() {
          _filterOptions = options;
        });
      }
    } catch (_) {
      // Ignore filter options loading errors
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final state = _cubit.state;
    if (state is ProductListLoading) return;
    if (state is ProductListLoaded && state.hasReachedMax) return;

    final position = _scrollController.position;
    final nearBottom = position.pixels >= position.maxScrollExtent - 200;
    final contentShorterThanViewport = position.maxScrollExtent <= 0;
    if (!nearBottom && !contentShorterThanViewport) return;

    _cubit.fetchProducts();
  }

  void _onSearch(String query) {
    _cubit.searchByKeyword(query);
  }

  ProductSearchCriteria _criteriaForFilter({
    required ProductListFilter filter,
    String? keyword,
  }) {
    switch (filter) {
      case ProductListFilter.readyToSell:
        return ProductSearchCriteria(
          keyword: keyword,
          businessStatuses: _catalogListStatuses,
          readinessFilter: ProductReadinessFilter.readyToSell,
          customFieldFilters: _customFieldFilters,
        );
      case ProductListFilter.incomplete:
        return ProductSearchCriteria(
          keyword: keyword,
          businessStatuses: _catalogListStatuses,
          readinessFilter: ProductReadinessFilter.incomplete,
          customFieldFilters: _customFieldFilters,
        );
      case ProductListFilter.inactive:
        return ProductSearchCriteria(
          keyword: keyword,
          businessStatuses: {ProductBusinessStatus.inactive},
          customFieldFilters: _customFieldFilters,
        );
      // case ProductListFilter.deleted:
      //   return ProductSearchCriteria(
      //     keyword: keyword,
      //     businessStatuses: {ProductBusinessStatus.softDeleted},
      //     includeSoftDeleted: true,
      //     customFieldFilters: _customFieldFilters,
      //   );
      default:
        // Stock filters and 'all' — include inactive; UI does local filtering for stock
        return ProductSearchCriteria(
          keyword: keyword,
          businessStatuses: _catalogListStatuses,
          customFieldFilters: _customFieldFilters,
        );
    }
  }

  void _showFilterBottomSheet() {
    showVBottomSheet(
      context: context,
      title: 'Lọc sản phẩm',
      child: CustomFieldFilterSheet(
        options: _filterOptions,
        initialFilters: _customFieldFilters,
        onApply: (newFilters) {
          setState(() {
            _customFieldFilters = newFilters;
          });

          final keyword = _cubit.state is ProductListLoaded
              ? (_cubit.state as ProductListLoaded).criteria.keyword
              : null;

          _cubit.fetchProducts(
            criteria: _criteriaForFilter(
              filter: _selectedFilter,
              keyword: keyword,
            ),
            isRefresh: true,
          );
        },
      ),
    );
  }

  void _onFilterChanged(ProductListFilter filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
    });

    final keyword = _cubit.state is ProductListLoaded
        ? (_cubit.state as ProductListLoaded).criteria.keyword
        : null;

    _cubit.fetchProducts(
      criteria: _criteriaForFilter(filter: filter, keyword: keyword),
      isRefresh: true,
    );
  }

  void _navigateToProductModel(BuildContext context, ProductListItemModel model) {
    context
        .push(
          '/products/items/pcc',
          extra: ProductControlCenterRouteArgs(product: model),
        )
        .then((_) {
          if (mounted) {
            _cubit.fetchProducts(isRefresh: true);
          }
        });
  }

  Future<void> _navigateToProduct(BuildContext context, ProductListItemDto dto) async {
    final readinessStatus = dto.readinessSummary.status == ReadinessStatus.readyToSell
        ? ProductReadinessStatus.ready
        : ProductReadinessStatus.needsReview;

    final model = ProductListItemModel(
      id: dto.id,
      name: dto.name,
      tradeName: dto.tradeName,
      sku: dto.sku,
      barcode: dto.barcode,
      imageUrl: dto.primaryImageUrl,
      businessStatus: dto.businessStatus,
      readinessStatus: readinessStatus,
      listBeforeVat: dto.listBeforeVat,
      floorBeforeVat: dto.floorBeforeVat,
      listAfterVat: dto.listAfterVat,
      floorAfterVat: dto.floorAfterVat,
      baseUnit: dto.baseUnit,
      stockQty: dto.stockQuantity,
      stockLabel: dto.stockLabel,
    );

    await context.push(
      '/products/items/pcc',
      extra: ProductControlCenterRouteArgs(product: model),
    );

    if (context.mounted) {
      _cubit.fetchProducts(isRefresh: true);
    }
  }

  Future<void> _onCreateProduct(BuildContext context) async {
    final createdProduct = await context.push<ProductListItemModel>('/products/items/new');
    if (!context.mounted) return;
    if (createdProduct != null) {
      _cubit.fetchProducts(isRefresh: true);
      _navigateToProductModel(context, createdProduct);
    } else {
      _cubit.fetchProducts(isRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<ProductListCubit, ProductListState>(
        builder: (context, state) {
          return VPageScaffold(
            key: const Key('wgt_e01_u01_fr01_01'),
            centerTitle: false,
            title: 'Sản phẩm',
            subtitle: '${_cubit.globalTotalCount ?? 0} sản phẩm',
            showBackButton: false,
            actions: [
              IconButton(
                icon: VIcon(
                  icon: VIcons.moreVert,
                  color: dynamicColors.textPrimary,
                ),
                onPressed: () {},
              ),
            ],
            floatingActionButton: VFloatingActionButton(
              key: const Key('btn_create_product'),
              icon: VIcons.add,
              tone: VComponentTone.success,
              backgroundColor: dynamicColors.success,
              semanticLabel: 'Tạo sản phẩm',
              onTap: () => _onCreateProduct(context),
            ),
            body: Column(
              children: [
                ProductListSearchBar(
                  onSearch: _onSearch,
                  onFilterPressed: _showFilterBottomSheet,
                  activeFiltersCount: _customFieldFilters.length,
                ),
                ProductCatalogFilterChips(
                  selectedFilter: _selectedFilter,
                  globalCount: _cubit.globalTotalCount,
                  filterCounts: {
                    if (_cubit.readyToSellCount != null)
                      ProductListFilter.readyToSell: _cubit.readyToSellCount!,
                    if (_cubit.incompleteCount != null)
                      ProductListFilter.incomplete: _cubit.incompleteCount!,
                    if (_cubit.inactiveCount != null)
                      ProductListFilter.inactive: _cubit.inactiveCount!,
                    if (_cubit.inStockCount != null)
                      ProductListFilter.inStock: _cubit.inStockCount!,
                    if (_cubit.outOfStockCount != null)
                      ProductListFilter.outOfStock: _cubit.outOfStockCount!,
                  },
                  onFilterChanged: _onFilterChanged,
                ),
                const SizedBox(height: VSpacing.space3),
                Expanded(
                  child: ProductCatalogListBody(
                    scrollController: _scrollController,
                    selectedFilter: _selectedFilter,
                    globalTotalCount: _cubit.globalTotalCount,
                    onRefresh: () => _cubit.fetchProducts(isRefresh: true),
                    onTapItem: (item) => _navigateToProduct(context, item),
                    onCreateProduct: () => _onCreateProduct(context),
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
