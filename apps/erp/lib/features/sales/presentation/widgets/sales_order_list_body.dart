import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/sales_order/sales_order_list_state.dart';
import '../models/sales_order/sales_order_list_item_vm.dart';
import 'sales_order_list_card.dart';
import 'sales_order_list_empty_state.dart';
import 'sales_order_list_error_state.dart';
import 'sales_order_list_no_result_state.dart';

class SalesOrderListBody extends StatelessWidget {
  const SalesOrderListBody({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onRetry,
    required this.onLoadMore,
    required this.onTapOrder,
    this.onCreateSale,
    this.onClearSearch,
    this.onClearFilters,
  });

  final SalesOrderListState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRetry;
  final Future<void> Function() onLoadMore;
  final ValueChanged<SalesOrderListItemVm> onTapOrder;
  final VoidCallback? onCreateSale;
  final VoidCallback? onClearSearch;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      SalesOrderListInitial() || SalesOrderListLoading() => const _OrderListSkeleton(),
      SalesOrderListError(:final message) => SalesOrderListErrorState(
        message: message,
        onRetry: () => onRetry(),
      ),
      SalesOrderListLoaded(
        :final items,
        :final isDefaultScopeEmpty,
        :final hasMore,
        :final isLoadingMore,
        :final loadMoreError,
        :final query,
        :final activeFilterCount,
      ) =>
        _LoadedBody(
          items: items,
          isDefaultScopeEmpty: isDefaultScopeEmpty,
          hasMore: hasMore,
          isLoadingMore: isLoadingMore,
          loadMoreError: loadMoreError,
          query: query,
          hasQuery: query != null && query.isNotEmpty,
          hasFilters: activeFilterCount > 0,
          onRefresh: onRefresh,
          onLoadMore: onLoadMore,
          onTapOrder: onTapOrder,
          onCreateSale: onCreateSale,
          onClearSearch: onClearSearch,
          onClearFilters: onClearFilters,
        ),
      SalesOrderListBlocked() => const SizedBox.shrink(),
    };
  }
}

class _OrderListSkeleton extends StatelessWidget {
  const _OrderListSkeleton();

  @override
  Widget build(BuildContext context) {
    return const VSkeletonScope(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: VPagePadding(
          child: Column(
            children: [
              _OrderCardSkeleton(index: 0),
              VGap.sm(),
              _OrderCardSkeleton(index: 1),
              VGap.sm(),
              _OrderCardSkeleton(index: 2),
              VGap.sm(),
              _OrderCardSkeleton(index: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCardSkeleton extends StatelessWidget {
  const _OrderCardSkeleton({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Container(
      key: Key('card_sales_order_skeleton_$index'),
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.borderDefault),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: VSkeleton(height: 24, width: 140, borderRadius: VRadius.r4),
              ),
              VGap.horizontalSm(),
              VSkeleton(height: 24, width: 72, borderRadius: VRadius.r4),
            ],
          ),
          VGap.xs(),
          VSkeleton(height: 20, width: 180, borderRadius: VRadius.r4),
          VGap.sm(),
          VSkeleton(height: 22, width: 110, borderRadius: VRadius.r4),
          VGap.sm(),
          Row(
            children: [
              Expanded(
                child: VSkeleton(height: 20, width: 90, borderRadius: VRadius.r4),
              ),
              VSkeleton(height: 20, width: 44, borderRadius: VRadius.r4),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.items,
    required this.isDefaultScopeEmpty,
    required this.hasMore,
    required this.isLoadingMore,
    required this.loadMoreError,
    this.query,
    required this.hasQuery,
    required this.hasFilters,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onTapOrder,
    this.onCreateSale,
    this.onClearSearch,
    this.onClearFilters,
  });

  final List<SalesOrderListItemVm> items;
  final bool isDefaultScopeEmpty;
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadMoreError;
  final String? query;
  final bool hasQuery;
  final bool hasFilters;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final ValueChanged<SalesOrderListItemVm> onTapOrder;
  final VoidCallback? onCreateSale;
  final VoidCallback? onClearSearch;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      if (isDefaultScopeEmpty && !hasQuery && !hasFilters) {
        return VPagePadding(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SalesOrderListEmptyState(onCreateSale: onCreateSale),
            ],
          ),
        );
      }
      return VPagePadding(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SalesOrderListNoResultState(
              searchTerm: hasQuery ? query : null,
              onClearSearch: hasQuery ? onClearSearch : null,
              onClearFilters: hasFilters ? onClearFilters : null,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: VPagePadding(
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            final metrics = notification.metrics;
            final nearBottom = metrics.pixels >= (metrics.maxScrollExtent - 200);
            if (nearBottom && hasMore && !isLoadingMore) {
              onLoadMore();
            }
            return false;
          },
          child: ListView.separated(
            key: const Key('list_sales_orders'),
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const VGap.sm(),
            itemBuilder: (context, index) {
              if (index >= items.length) {
                if (isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: VSpacing.space2),
                    child: Center(child: VLoading()),
                  );
                }
                if (loadMoreError != null) {
                  return VCard(
                    padding: const EdgeInsets.all(VSpacing.space3),
                    child: Row(
                      children: [
                        Expanded(
                          child: VText(
                            loadMoreError!,
                            color: context.vColors.danger,
                          ),
                        ),
                        VButton(
                          key: const Key('btn_sales_order_list_retry_load_more'),
                          size: VButtonSize.small,
                          tone: VComponentTone.neutral,
                          label: 'Thu lai',
                          onPressed: onLoadMore,
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }
              final item = items[index];
              return SalesOrderListCard(
                item: item,
                onTap: () => onTapOrder(item),
              );
            },
          ),
        ),
      ),
    );
  }
}
