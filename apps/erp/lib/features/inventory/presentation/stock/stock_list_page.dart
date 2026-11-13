import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/data/stock/stock_repository.dart';
import 'package:erp/features/inventory/logic/inventory_format.dart';
import 'package:erp/features/inventory/logic/stock/stale_watcher.dart';
import 'package:erp/features/inventory/logic/stock/stock_detail_cubit.dart';
import 'package:erp/features/inventory/logic/stock/stock_detail_state.dart';
import 'package:erp/features/inventory/logic/stock/stock_list_cubit.dart';
import 'package:erp/features/inventory/logic/stock/stock_list_rules.dart';
import 'package:erp/features/inventory/logic/stock/stock_list_state.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_states.dart';
import 'package:erp/features/inventory/presentation/stock/stock_detail_body.dart';
import 'package:erp/features/inventory/presentation/stock/stock_indicator_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

String formatStockContextAsOf(DateTime asOf) {
  final hh = asOf.hour.toString().padLeft(2, '0');
  final mm = asOf.minute.toString().padLeft(2, '0');
  final dd = asOf.day.toString().padLeft(2, '0');
  final mo = asOf.month.toString().padLeft(2, '0');
  final yyyy = asOf.year.toString();
  return '$hh:$mm, $dd/$mo/$yyyy';
}

class StockListPage extends StatelessWidget {
  final StaleWatcher? stale;
  final StockFilter? initialFilter;
  final String? initialQuery;

  const StockListPage({
    super.key,
    this.stale,
    this.initialFilter,
    this.initialQuery,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = StockListCubit(
          repository: getIt<StockRepository>(),
          stale: stale,
        );
        if (initialFilter != null) {
          cubit.setFilter(initialFilter!);
        }
        if (initialQuery != null && initialQuery!.trim().isNotEmpty) {
          cubit.setQuery(initialQuery!);
        }
        cubit.load();
        return cubit;
      },
      child: _StockListView(
        stale: stale,
        initialQuery: initialQuery,
      ),
    );
  }
}

class _StockListView extends StatefulWidget {
  final StaleWatcher? stale;
  final String? initialQuery;

  const _StockListView({
    this.stale,
    this.initialQuery,
  });

  @override
  State<_StockListView> createState() => _StockListViewState();
}

class _StockListViewState extends State<_StockListView>
    with WidgetsBindingObserver {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<StockListCubit>().checkStale();
    }
  }

  void _backToHub(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/warehouse');
    }
  }

  Future<void> _openDetail(BuildContext context, StockOverviewItem item) async {
    final cubit = context.read<StockListCubit>();
    await context.push('/warehouse/stock/${item.productId}', extra: item.name);
    if (mounted) {
      cubit.checkStale();
    }
  }

  String _rowSubtitle(StockOverviewItem item, StockFilter filter) {
    final primary = primaryIndicator(
      item.indicators,
      filter: filter.indicator,
    );
    if (primary == StockIndicator.notConfigured) {
      return '${item.code} · ${primary!.label}';
    }
    return item.code;
  }

  Widget? _rowBadge(StockOverviewItem item, StockFilter filter) {
    final primary = primaryIndicator(
      item.indicators,
      filter: filter.indicator,
    );
    if (primary == null || primary.tone == null) return null;
    final tone = primary.tone!;
    return VBadge(
      label: primary.label,
      tone: tone,
      showDot: true,
      hollowDot: tone == VComponentTone.danger,
    );
  }

  Widget _buildMobileRow(
    BuildContext context,
    StockOverviewItem item,
    StockFilter filter,
  ) {
    return VStockRow(
      title: item.name,
      subtitle: _rowSubtitle(item, filter),
      quantity: formatStockQuantity(item.available, item.uom),
      badge: _rowBadge(item, filter),
      onTap: () => _openDetail(context, item),
    );
  }

  Widget _buildWebTable(
    BuildContext context,
    StockListCubit cubit,
    StockListState state,
    List<StockOverviewItem> visible,
  ) {
    final colors = context.vColors;
    return K7Table<StockOverviewItem>(
      columns: [
        K7Column(
          label: 'Sản phẩm',
          cell: (item) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                item.code,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  color: context.vColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        K7Column(
          label: 'Khả dụng',
          numeric: true,
          cell: (item) => Text(
            formatStockQuantity(item.available, item.uom),
            style: TextStyle(
              fontFamily: VTypography.monoFontFamily,
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        K7Column(
          label: 'Tồn vật lý',
          numeric: true,
          cell: (item) => Text(
            formatStockQuantity(item.physical, item.uom),
            style: TextStyle(
              fontFamily: VTypography.monoFontFamily,
              fontSize: 14,
              height: 20 / 14,
              color: colors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        K7Column(
          label: 'Chỉ báo',
          cell: (item) => StockIndicatorBadge(
            indicators: item.indicators,
            filter: state.filter.indicator,
          ),
        ),
      ],
      rows: visible,
      selected: state.selected,
      mobileRow: (item) => _buildMobileRow(context, item, state.filter),
      onRowTap: (item) => cubit.select(item.productId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<StockListCubit>();
    final state = cubit.state;
    final isWide = inventoryIsWide(context);

    return Scaffold(
      appBar: VAppBar(
        title: 'Tồn kho',
        showBackButton: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quay về Kho',
          onPressed: () => _backToHub(context),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (state.status == StockListStatus.denied) {
            return Center(
              child: InventoryDenied(
                what: 'xem tồn kho',
                next:
                    'Bạn chưa được cấp quyền xem tồn kho. Liên hệ chủ cửa hàng nếu cần.',
                onExit: () => context.go('/warehouse'),
              ),
            );
          }

          if (state.status == StockListStatus.loading && state.data == null) {
            return const Padding(
              padding: EdgeInsets.all(VSpacing.space4),
              child: InventoryLoading(
                blocks: [
                  InventorySkeletonBlock.search,
                  InventorySkeletonBlock.row,
                  InventorySkeletonBlock.row,
                  InventorySkeletonBlock.row,
                  InventorySkeletonBlock.row,
                ],
              ),
            );
          }

          if (state.status == StockListStatus.loadError && state.data == null) {
            return Center(
              child: InventoryEmpty(
                title: 'Không thể tải dữ liệu tồn kho',
                description: state.error?.userMessage() ??
                    'Đã có lỗi xảy ra khi tải dữ liệu.',
                actionLabel: 'Thử lại',
                onAction: cubit.load,
              ),
            );
          }

          final data = state.data;
          if (data == null) return const SizedBox.shrink();

          final visible = state.visible;
          final selected = state.selected;

          Widget buildHeaderAndControls() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${data.warehouseName} · Dữ liệu đến ${formatStockContextAsOf(data.asOf)}',
                  style: TextStyle(
                    fontSize: 13,
                    height: 20 / 13,
                    color: context.vColors.textSecondary,
                  ),
                ),
                const SizedBox(height: VSpacing.space3),
                if (state.stale) ...[
                  InventoryStale(
                    title: 'Dữ liệu có thể đã cũ',
                    description: 'Hãy làm mới trước khi sử dụng.',
                    actionLabel: 'Làm mới',
                    onAction: cubit.refresh,
                  ),
                  const SizedBox(height: VSpacing.space3),
                ],
                VSearchBar(
                  hintText: 'Tên, mã sản phẩm hoặc mã vạch',
                  controller: _searchController,
                  onChanged: cubit.setQuery,
                  onClear: () => cubit.setQuery(''),
                ),
                const SizedBox(height: VSpacing.space3),
                K7FilterChips(
                  items: [
                    for (final f in StockFilter.values)
                      K7Filter(
                        key: f.name,
                        label: f.label,
                        count: filterCount(data.products, f),
                      ),
                  ],
                  selected: state.filter.name,
                  onSelected: (key) {
                    final filter = StockFilter.values.firstWhere(
                      (f) => f.name == key,
                      orElse: () => StockFilter.all,
                    );
                    cubit.setFilter(filter);
                  },
                ),
                const SizedBox(height: VSpacing.space3),
              ],
            );
          }

          Widget content;
          if (state.status == StockListStatus.empty || data.products.isEmpty) {
            content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${data.warehouseName} · Dữ liệu đến ${formatStockContextAsOf(data.asOf)}',
                  style: TextStyle(
                    fontSize: 13,
                    height: 20 / 13,
                    color: context.vColors.textSecondary,
                  ),
                ),
                const SizedBox(height: VSpacing.space3),
                const InventoryEmpty(
                  title: 'Chưa có dữ liệu tồn kho',
                  description: 'Không có dữ liệu trong kho hiện tại.',
                ),
              ],
            );
          } else if (visible.isEmpty) {
            content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                buildHeaderAndControls(),
                InventoryEmpty(
                  title: 'Không có kết quả phù hợp',
                  description: 'Thử tên, mã sản phẩm hoặc chọn bộ lọc khác.',
                  actionLabel: 'Xóa tìm kiếm và bộ lọc',
                  onAction: () {
                    _searchController.clear();
                    cubit.clearSearchAndFilter();
                  },
                ),
              ],
            );
          } else if (isWide && selected != null) {
            content = K7Split(
              wideMain: true,
              asideWebOnly: true,
              main: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildHeaderAndControls(),
                  _buildWebTable(context, cubit, state, visible),
                ],
              ),
              aside: StockDetailPanel(
                productId: selected.productId,
                listAsOf: data.asOf,
                stale: widget.stale,
                onThresholdSaved: cubit.refresh,
              ),
            );
          } else {
            content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                buildHeaderAndControls(),
                for (var i = 0; i < visible.length; i++) ...[
                  _buildMobileRow(context, visible[i], state.filter),
                  if (i < visible.length - 1)
                    const SizedBox(height: VSpacing.space2),
                ],
              ],
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 1160 : double.infinity,
                ),
                child: content,
              ),
            ),
          );
        },
      ),
    );
  }
}

class StockDetailPanel extends StatefulWidget {
  final String productId;

  /// Mốc "Dữ liệu đến" của danh sách: đổi (danh sách vừa làm mới) ⇒ cột phải tải lại.
  final DateTime? listAsOf;
  final StaleWatcher? stale;
  final VoidCallback? onThresholdSaved;

  const StockDetailPanel({
    super.key,
    required this.productId,
    this.listAsOf,
    this.stale,
    this.onThresholdSaved,
  });

  @override
  State<StockDetailPanel> createState() => _StockDetailPanelState();
}

class _StockDetailPanelState extends State<StockDetailPanel> {
  late final StockDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = StockDetailCubit(
      repository: getIt<StockRepository>(),
      stale: widget.stale,
    )..load(widget.productId);
  }

  @override
  void didUpdateWidget(covariant StockDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _cubit.load(widget.productId);
    } else if (oldWidget.listAsOf != widget.listAsOf) {
      _cubit.refresh();
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _editThreshold(BuildContext context, String productId) async {
    final saved = await context.push<bool>(
      '/warehouse/stock-policy/product/$productId',
    );
    if (!mounted) return;
    if (saved == true) {
      // Tự tải lại trước (không phụ thuộc danh sách làm mới thành công), rồi làm mới danh sách.
      await _cubit.refresh();
      widget.onThresholdSaved?.call();
    } else {
      _cubit.checkStale();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockDetailCubit, StockDetailState>(
      bloc: _cubit,
      builder: (context, state) {
        if (state.status == StockDetailStatus.loading && state.data == null) {
          return const InventoryLoading(
            blocks: [
              InventorySkeletonBlock.card,
              InventorySkeletonBlock.row,
              InventorySkeletonBlock.row,
            ],
          );
        }

        if (state.status == StockDetailStatus.loadError && state.data == null) {
          return InventoryEmpty(
            title: 'Không thể tải chi tiết tồn kho',
            description: state.error?.userMessage() ??
                'Đã có lỗi xảy ra khi tải dữ liệu.',
            actionLabel: 'Thử lại',
            onAction: () => _cubit.load(widget.productId),
          );
        }

        final detail = state.data;
        if (detail == null) return const SizedBox.shrink();

        return StockDetailBody(
          detail: detail,
          singleColumn: true,
          onEditThreshold: () => _editThreshold(context, detail.productId),
        );
      },
    );
  }
}
