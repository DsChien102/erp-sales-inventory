import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_presentation/presentation.dart';

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
          icon: VIcons.warning,
          title: 'Không thể tải lịch sử thao tác',
          description: state.errorMessage ?? 'Đã xảy ra lỗi',
          actionLabel: 'Thử lại',
          onActionPressed: onRetry,
          tone: VComponentTone.danger,
        ),
      );
    }

    if (state.items.isEmpty) {
      return const Center(
        child: VEmptyState(
          icon: VIcons.history,
          title: 'Chưa có lịch sử thao tác nào',
          description: 'Các thay đổi của KH & NCC sẽ xuất hiện tại đây.',
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
