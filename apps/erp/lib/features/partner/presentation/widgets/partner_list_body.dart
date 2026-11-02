import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:erp/features/partner/presentation.dart';

/// List / loading / error / empty body for partner list page.
class PartnerListBody extends StatelessWidget {
  const PartnerListBody({
    super.key,
    required this.scrollController,
    required this.canCreate,
    required this.onRefresh,
    required this.onRetry,
    required this.onClearQuery,
    required this.onCreate,
    required this.onTapPartner,
    this.selectedId,
  });

  /// Viewport-friendly skeleton count for first load / refresh (option B).
  static const int firstLoadSkeletonCount = 8;

  final ScrollController scrollController;
  final bool canCreate;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final VoidCallback onClearQuery;
  final VoidCallback onCreate;
  final ValueChanged<String> onTapPartner;

  /// Hồ sơ đang mở ở cột phải (web rộng); null khi không có.
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocBuilder<PartnerListCubit, PartnerListState>(
      builder: (context, state) {
        if (state is PartnerListInitial || (state is PartnerListLoading && state.isFirstLoad)) {
          return VSkeletonScope(
            child: VPagePadding(
              child: ListView.separated(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: VSpacing.md),
                itemCount: firstLoadSkeletonCount,
                separatorBuilder: (context, index) => const SizedBox(height: VSpacing.space3),
                itemBuilder: (context, index) => const PartnerListItemSkeletonTile(),
              ),
            ),
          );
        }

        if (state is PartnerListError) {
          return Center(
            child: VEmptyState(
              tone: VComponentTone.danger,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const VEmptyHeader(
                    children: [
                      VEmptyMedia(icon: VIcons.cloudOff),
                      VEmptyTitle('Không tải được danh sách'),
                      VEmptyDescription(
                        'Vui lòng kiểm tra kết nối internet\nhoặc thử lại sau.',
                      ),
                    ],
                  ),
                  const VGap.xl(),
                  VEmptyContent(
                    child: VButton(
                      label: 'Thử lại',
                      onPressed: onRetry,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final items = switch (state) {
          PartnerListLoaded(:final items) => items,
          PartnerListLoading(:final items) => items,
          _ => <PartnerListItemDto>[],
        };

        if (items.isEmpty && state is! PartnerListLoading) {
          final hasQuery = state.query != null && state.query!.isNotEmpty;
          if (hasQuery) {
            return Column(
              children: [
                VPagePadding(
                  child: VEmptyState(
                    backgroundColor: colors.surface,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VEmptyHeader(
                          children: [
                            const VEmptyMedia(icon: VIcons.search),
                            const VEmptyTitle('Không tìm thấy kết quả'),
                            const VGap(VSpacing.space2),
                            VEmptyDescription(
                              'Thử kiểm tra lại từ khóa "${state.query}"\nhoặc bộ lọc.',
                            ),
                          ],
                        ),
                        const VGap(VSpacing.space2),
                        VEmptyContent(
                          child: VButton(
                            label: 'Xóa từ khóa',
                            onPressed: onClearQuery,
                            variant: VButtonVariant.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              VPagePadding(
                child: VEmptyState(
                  backgroundColor: colors.surface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const VEmptyHeader(
                        children: [
                          VEmptyMedia(icon: VIcons.people),
                          VEmptyTitle('Chưa có KH & NCC'),
                          VGap(VSpacing.space2),
                          VEmptyDescription(
                            'Thêm đối tác để bắt đầu bán hàng,\nnhập hàng và quản lý công nợ.',
                          ),
                        ],
                      ),
                      if (canCreate) ...[
                        const VGap(VSpacing.space2),
                        VEmptyContent(
                          child: VButton(
                            label: 'Thêm KH & NCC',
                            onPressed: onCreate,
                            variant: VButtonVariant.tertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        final isLoadingMore = state is PartnerListLoading && !state.isFirstLoad;
        final hasReachedMax = state is PartnerListLoaded && state.hasReachedMax;

        final int trailingCount;
        if (isLoadingMore) {
          trailingCount = PartnerListCubit.pageSize;
        } else if (hasReachedMax && items.isNotEmpty) {
          trailingCount = 1;
        } else {
          trailingCount = 0;
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          displacement: VSpacing.md,
          child: VPagePadding(
            child: ListView.separated(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: VSpacing.md),
              itemCount: items.length + trailingCount,
              separatorBuilder: (context, index) => const SizedBox(height: VSpacing.space3),
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  if (isLoadingMore) {
                    // Local VSkeleton controllers — avoid wrapping the whole
                    // list in VSkeletonScope (blocks pumpAndSettle in tests).
                    return const PartnerListItemSkeletonTile();
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: VSpacing.space2,
                    ),
                    child: Center(
                      child: VText(
                        'Đã ở cuối danh sách',
                        variant: VTextVariant.labelSmall,
                        color: colors.textMuted,
                      ),
                    ),
                  );
                }
                final item = items[index];
                return PartnerListItemTile(
                  item: item,
                  isSelected: item.partnerId == selectedId,
                  onTap: () => onTapPartner(item.partnerId),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
