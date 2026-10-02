import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart' as iam;
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:vet45_shared_application/application.dart';

/// SG-07 — Danh sách đơn hàng (EP-03/US-01).
class SalesOrderListPage extends StatefulWidget {
  const SalesOrderListPage({super.key});

  @override
  State<SalesOrderListPage> createState() => _SalesOrderListPageState();
}

class _SalesOrderListPageState extends State<SalesOrderListPage> {
  late final SalesOrderListCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SalesOrderListCubit(
      salesModule: GetIt.instance<ISalesModule>(),
      executionContext: GetIt.instance<IExecutionContext>(),
      activeStoreContext: _SalesActiveStoreAdapter(
        GetIt.instance<iam.IActiveStoreContext>(),
      ),
    )..load(isRefresh: true);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openFilterSheet(SalesOrderListState state) async {
    final result = await SalesOrderFilterBottomSheet.show(
      context,
      timeFilter: state.timeFilter,
      lifecycleFilter: state.lifecycleFilter,
      settlementFilter: state.settlementFilter,
      postSaleFilter: state.postSaleFilter,
      eInvoiceFilter: state.eInvoiceFilter,
    );
    if (result == null || !mounted) return;
    _cubit.applyFilters(
      timeFilter: result.timeFilter,
      lifecycleFilter: result.lifecycleFilter,
      settlementFilter: result.settlementFilter,
      postSaleFilter: result.postSaleFilter,
      eInvoiceFilter: result.eInvoiceFilter,
    );
  }

  void _openCreateOrder() {
    const SalesComposeRoute().push(context);
  }

  void _openOrderDetail(SalesOrderListItemVm item) {
    SalesOrderDetailRoute(orderId: item.salesOrderId).push(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<SalesOrderListCubit, SalesOrderListState>(
        builder: (context, state) {
          if (state is SalesOrderListBlocked) {
            return VPageScaffold(
              key: const Key('wgt_e03_u01_page'),
              title: 'Đơn hàng',
              showBackButton: false,
              body: SalesOrderListBlockedState(
                onBack: () => context.go('/'),
              ),
            );
          }

          final subtitleText =
              (state is SalesOrderListLoading && state.isFirstLoad && state.totalAvailable == 0)
              ? 'Đang tải…'
              : '${state.totalAvailable} đơn hàng';

          return VPageScaffold(
            key: const Key('wgt_e03_u01_page'),
            title: 'Đơn hàng',
            subtitle: subtitleText,
            centerTitle: false,
            showBackButton: false,
            floatingActionButton: VFloatingActionButton(
              key: const Key('btn_sales_create_order'),
              icon: VIcons.add,
              tone: VComponentTone.success,
              backgroundColor: context.vColors.success,
              semanticLabel: 'Tạo đơn bán hàng',
              onTap: _openCreateOrder,
            ),
            body: Column(
              children: [
                const VGap.sm(),
                VPagePadding(
                  child: SalesOrderListSearchBar(
                    initialQuery: state.query,
                    activeFilterCount: state.activeFilterCount,
                    onSearch: _cubit.searchByKeyword,
                    onFilterTap: () => _openFilterSheet(state),
                  ),
                ),
                const VGap.sm(),
                VPagePadding(
                  child: SalesOrderSavedSearchChips(
                    selected: state.preset,
                    onSelected: _cubit.selectPreset,
                  ),
                ),
                const VGap.sm(),
                Expanded(
                  child: SalesOrderListBody(
                    state: state,
                    onRefresh: _cubit.refresh,
                    onRetry: _cubit.refresh,
                    onLoadMore: _cubit.loadMore,
                    onTapOrder: _openOrderDetail,
                    onCreateSale: _openCreateOrder,
                    onClearSearch: () => _cubit.clearSearch(),
                    onClearFilters: () => _cubit.clearFilters(),
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

final class _SalesActiveStoreAdapter implements ISalesActiveStoreContext {
  const _SalesActiveStoreAdapter(this._inner);

  final iam.IActiveStoreContext _inner;

  @override
  String? get activeStoreId => _inner.activeStoreId;

  @override
  Future<String> requireActiveStoreId() => _inner.requireActiveStoreId();
}
