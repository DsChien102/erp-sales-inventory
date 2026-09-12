import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/partner/presentation.dart';

import 'partner_change_history_card.dart';

class PartnerChangeHistoryBody extends StatelessWidget {
  const PartnerChangeHistoryBody({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onRefresh,
  });

  final PartnerChangeHistoryState state;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (state.status == PartnerChangeHistoryStatus.initial ||
        state.status == PartnerChangeHistoryStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == PartnerChangeHistoryStatus.failure) {
      return Center(
        child: VEmptyState(
          tone: VComponentTone.danger,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VEmptyHeader(
                children: [
                  const VEmptyMedia(icon: VIcons.warning),
                  const VEmptyTitle('Không thể tải lịch sử thao tác'),
                  VEmptyDescription(state.errorMessage ?? 'Đã xảy ra lỗi'),
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

    if (state.items.isEmpty) {
      return const Center(
        child: VEmptyState(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VEmptyHeader(
                children: [
                  VEmptyMedia(icon: VIcons.history),
                  VEmptyTitle('Chưa có lịch sử thao tác nào'),
                  VEmptyDescription(
                    'Các thay đổi của KH & NCC sẽ xuất hiện tại đây.',
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: VPagePadding(
        vertical: VSpacing.md,
        applyBottomSafeArea: true,
        child: ListView.separated(
          itemCount: state.items.length,
          separatorBuilder: (_, _) => const VGap.sm(),
          itemBuilder: (context, index) => PartnerChangeHistoryCard(
            entry: state.items[index],
          ),
        ),
      ),
    );
  }
}
