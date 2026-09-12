import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/sales_order_draft/sales_draft_list_state.dart';
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

    final allItems = switch (state) {
      SalesDraftListLoaded(:final items) => items,
      SalesDraftListLoading(:final items) => items,
      _ => const <SalesDraftListItemVm>[],
    };
    final items = displayScope == SalesDraftScopeFilter.mine
        ? allItems.where((i) => i.isOwnedByMe).toList()
        : allItems;
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

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        key: Key('list_sales_drafts_${displayScope.name}'),
        padding: const EdgeInsets.fromLTRB(
          VSpacing.space4,
          VSpacing.space4,
          VSpacing.space4,
          VSpacing.space10,
        ),
        itemCount: items.length,
        separatorBuilder: (_, _) => const VGap.sm(),
        itemBuilder: (context, index) {
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
    );
  }
}
