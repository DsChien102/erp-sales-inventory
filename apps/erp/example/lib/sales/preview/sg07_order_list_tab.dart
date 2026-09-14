import 'package:flutter/material.dart';
import 'package:erp/features/sales/presentation.dart';

import 'fixtures.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';

class SalesSg07OrderListTab extends StatelessWidget {
  const SalesSg07OrderListTab({super.key});

  static Future<void> _noop() async {}

  static const _counts = {
    SalesOrderSavedSearchPreset.all: 12,
    SalesOrderSavedSearchPreset.outstandingReceivable: 3,
    SalesOrderSavedSearchPreset.eInvoicePending: 5,
  };

  @override
  Widget build(BuildContext context) {
    return previewList([
      PreviewSection(
        title: 'SalesOrderListSearchBar',
        child: SalesOrderListSearchBar(
          onSearch: (_) {},
          onFilterTap: () {},
          activeFilterCount: 2,
          initialQuery: 'DH-000',
        ),
      ),
      PreviewSection(
        title: 'SalesOrderSavedSearchChips',
        child: SalesOrderSavedSearchChips(
          selected: SalesOrderSavedSearchPreset.all,
          counts: _counts,
          onSelected: (_) {},
        ),
      ),
      PreviewSection(
        title: 'SalesOrderListCard',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Paid',
              child: SalesOrderListCard(
                item: SalesPreviewFixtures.orderCompleted,
                onTap: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Partially paid',
              child: SalesOrderListCard(
                item: SalesPreviewFixtures.orderPartial,
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'Empty / error / no-result / blocked',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Empty',
              child: SalesOrderListEmptyState(onCreateSale: () {}),
            ),
            PreviewStateRow(
              label: 'Error',
              child: SalesOrderListErrorState(
                message: 'Không thể tải danh sách',
                onRetry: () {},
              ),
            ),
            PreviewStateRow(
              label: 'No result',
              child: SalesOrderListNoResultState(
                onClearSearch: () {},
                onClearFilters: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Blocked',
              child: SalesOrderListBlockedState(onBack: () {}),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SalesOrderListBody',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Loading',
              child: PreviewEmbedFrame(
                height: 160,
                child: SalesOrderListBody(
                  state: const SalesOrderListLoading(items: []),
                  onRefresh: _noop,
                  onRetry: _noop,
                  onLoadMore: _noop,
                  onTapOrder: (_) {},
                ),
              ),
            ),
            PreviewStateRow(
              label: 'Filled',
              child: PreviewEmbedFrame(
                height: 280,
                child: SalesOrderListBody(
                  state: SalesOrderListLoaded(
                    items: SalesPreviewFixtures.orders,
                    hasMore: false,
                    requestGeneration: 1,
                    totalMatching: 2,
                  ),
                  onRefresh: _noop,
                  onRetry: _noop,
                  onLoadMore: _noop,
                  onTapOrder: (_) {},
                ),
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SalesOrderFilterBottomSheet',
        child: PreviewActionButton(
          label: 'Mở bộ lọc',
          onPressed: () => SalesOrderFilterBottomSheet.show(
            context,
            timeFilter: SalesOrderListTimeFilter.all,
            lifecycleFilter: SalesOrderListLifecycleFilter.all,
            settlementFilter: SalesOrderListSettlementFilter.all,
            postSaleFilter: SalesOrderListPostSaleFilter.all,
            eInvoiceFilter: SalesOrderListEInvoiceFilter.all,
          ),
        ),
      ),
    ]);
  }
}
