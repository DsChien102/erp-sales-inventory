import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/sales/presentation.dart';

import 'fixtures.dart';
import 'preview_helpers.dart';
import 'preview_section.dart';

class SalesSg01DraftsTab extends StatelessWidget {
  const SalesSg01DraftsTab({super.key});

  static Future<void> _noopRefresh() async {}

  @override
  Widget build(BuildContext context) {
    return previewList([
      PreviewSection(
        title: 'SalesDraftListSearchBar',
        child: SalesDraftListSearchBar(onSearch: (_) {}, initialQuery: 'An'),
      ),
      PreviewSection(
        title: 'SalesDraftListCard',
        description: 'Composing vs needs-check; swipe xóa trên card.',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Composing',
              child: SalesDraftListCard(
                item: SalesPreviewFixtures.draftComposing,
                showCreatedBy: false,
                onTap: () {},
                onDiscard: () {},
              ),
            ),
            PreviewStateRow(
              label: 'Needs check + createdBy',
              child: SalesDraftListCard(
                item: SalesPreviewFixtures.draftNeedsCheck,
                showCreatedBy: true,
                onTap: () {},
                onDiscard: () {},
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'Empty / error / no-result',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Empty',
              child: SalesDraftListEmptyState(onRetry: () {}),
            ),
            PreviewStateRow(
              label: 'Error',
              child: SalesDraftListErrorState(
                message: 'Mất kết nối mạng',
                onRetry: () {},
              ),
            ),
            PreviewStateRow(
              label: 'No result',
              child: SalesDraftListNoResultState(
                query: 'xyz',
                onClearSearch: () {},
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'SalesDraftListCardSkeleton',
        description: 'First-load placeholder — mimic card layout.',
        child: const VSkeletonScope(
          child: SalesDraftListCardSkeleton(),
        ),
      ),
      PreviewSection(
        title: 'SalesDraftListBody',
        description: 'loading / filled / empty qua state object.',
        child: Column(
          children: [
            PreviewStateRow(
              label: 'Loading (skeleton)',
              child: PreviewEmbedFrame(
                height: 420,
                child: SalesDraftListBody(
                  state: const SalesDraftListLoading(items: []),
                  displayScope: SalesDraftScopeFilter.mine,
                  onRefresh: _noopRefresh,
                  onRetry: () {},
                  onTapDraft: (_) {},
                  onDiscardDraft: (_) {},
                ),
              ),
            ),
            PreviewStateRow(
              label: 'Filled',
              child: PreviewEmbedFrame(
                height: 280,
                child: SalesDraftListBody(
                  state: SalesDraftListLoaded(
                    items: SalesPreviewFixtures.drafts,
                    isDefaultEmpty: false,
                  ),
                  displayScope: SalesDraftScopeFilter.mine,
                  onRefresh: _noopRefresh,
                  onRetry: () {},
                  onTapDraft: (_) {},
                  onDiscardDraft: (_) {},
                ),
              ),
            ),
          ],
        ),
      ),
      PreviewSection(
        title: 'showSalesDraftDiscardDialog',
        child: PreviewActionButton(
          label: 'Mở xác nhận xóa nháp',
          onPressed: () {
            showSalesDraftDiscardDialog(
              context,
              item: SalesPreviewFixtures.draftComposing,
            );
          },
        ),
      ),
    ]);
  }
}
