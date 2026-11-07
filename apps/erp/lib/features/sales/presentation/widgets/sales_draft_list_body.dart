import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'package:erp/features/sales/logic/sales_draft_list_state.dart';
import '../models/sales_order_draft/sales_draft_list_item_vm.dart';
import 'sales_draft_list_card.dart';
import 'sales_draft_list_card_skeleton.dart';
import 'sales_draft_list_empty_state.dart';
import 'sales_draft_list_error_state.dart';
import 'sales_draft_list_no_result_state.dart';

/// Nội dung list theo một tab scope (mine / all).
class SalesDraftListBody extends StatelessWidget {
  const SalesDraftListBody({
    super.key,
    required this.state,
    required this.displayScope,
    required this.onRefresh,
    required this.onRetry,
    required this.onTapDraft,
    required this.onDiscardDraft,
    this.onClearSearch,
    this.onLoadMore,
  });

  /// Viewport-friendly skeleton count for first load.
  static const int firstLoadSkeletonCount = 8;

  final SalesDraftListState state;
  final SalesDraftScopeFilter displayScope;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final ValueChanged<SalesDraftListItemVm> onTapDraft;
  final ValueChanged<SalesDraftListItemVm> onDiscardDraft;
  final VoidCallback? onClearSearch;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (state is SalesDraftListInitial ||
        (state is SalesDraftListLoading && (state as SalesDraftListLoading).isFirstLoad)) {
      return VSkeletonScope(
        child: ListView.separated(
          key: const Key('list_sales_drafts_skeleton'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            VSpacing.space4,
            VSpacing.space4,
            VSpacing.space4,
            VSpacing.space10,
          ),
          itemCount: firstLoadSkeletonCount,
          separatorBuilder: (_, _) => const VGap.sm(),
          itemBuilder: (context, index) => SalesDraftListCardSkeleton(
            key: Key('card_sales_draft_skeleton_$index'),
          ),
        ),
      );
    }

    if (state is SalesDraftListError) {
      final error = state as SalesDraftListError;
      return Column(
        children: [
          VPagePadding(
            vertical: VSpacing.md,
            child: SalesDraftListErrorState(
              message: error.message,
              onRetry: onRetry,
            ),
          ),
        ],
      );
    }

    if (state is SalesDraftListBlocked) {
      return const Center(
        child: VEmptyState(
          key: Key('wgt_e01_u01_blocked'),
          child: VEmptyHeader(
            children: [
              VEmptyMedia(icon: VIcons.lock),
              VEmptyTitle('Không thể mở đơn nháp'),
              VEmptyDescription('Anh/chị không có quyền truy cập khu vực bán hàng.'),
            ],
          ),
        ),
      );
    }

    final items = switch (state) {
      SalesDraftListLoaded(:final items) => items,
      SalesDraftListLoading(:final items) => items,
      _ => const <SalesDraftListItemVm>[],
    };
    final hasQuery = (state.query ?? '').isNotEmpty;
    final showCreatedBy = displayScope == SalesDraftScopeFilter.all;

    if (items.isEmpty) {
      return Column(
        children: [
          VPagePadding(
            vertical: VSpacing.md,
            child: hasQuery
                ? SalesDraftListNoResultState(
                    query: state.query!,
                    onClearSearch: onClearSearch ?? () {},
                  )
                : const SalesDraftListEmptyState(),
          ),
        ],
      );
    }

    final hasFooter = state.isLoadingMore || state.loadMoreError != null;
    final itemCount = items.length + (hasFooter ? 1 : 0);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 300) {
            if (state.hasMore && !state.isLoadingMore) {
              onLoadMore?.call();
            }
          }
          return false;
        },
        child: ListView.separated(
          key: Key('list_sales_drafts_${displayScope.name}'),
          padding: const EdgeInsets.fromLTRB(
            VSpacing.space4,
            VSpacing.space4,
            VSpacing.space4,
            VSpacing.space10,
          ),
          itemCount: itemCount,
          separatorBuilder: (_, _) => const VGap.sm(),
          itemBuilder: (context, index) {
            if (index == items.length) {
              if (state.isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: VSpacing.space4),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                );
              }
              if (state.loadMoreError != null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: VSpacing.space2),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: onLoadMore,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(
                        '${state.loadMoreError} · Thử lại',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                );
              }
            }
            final item = items[index];
            return SalesDraftListCard(
              key: Key('card_sales_draft_${item.draftId}'),
              item: item,
              showCreatedBy: showCreatedBy,
              onTap: () => onTapDraft(item),
              onDiscard: () => onDiscardDraft(item),
            );
          },
        ),
      ),
    );
  }
}
