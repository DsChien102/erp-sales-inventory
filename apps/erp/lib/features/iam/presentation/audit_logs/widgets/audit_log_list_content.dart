import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../models/audit_log_ui_model.dart';
import 'audit_log_item_card.dart';

/// Widget danh sách nội dung nhật ký thao tác (render cuộn ListView.separated chuẩn theo OrganizationListContent).
class AuditLogListContent extends StatelessWidget {
  final List<AuditLogItemUiModel> logs;
  final ValueChanged<AuditLogItemUiModel>? onItemTap;
  final Future<void> Function()? onRefresh;

  const AuditLogListContent({
    super.key,
    required this.logs,
    this.onItemTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    if (logs.isEmpty) {
      final emptyBody = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space8,
        ),
        child: Center(
          child: VText(
            'Không tìm thấy nhật ký thao tác phù hợp.',
            color: colors.textSecondary,
          ),
        ),
      );

      if (onRefresh != null) {
        return RefreshIndicator(
          color: colors.primary,
          onRefresh: onRefresh!,
          child: emptyBody,
        );
      }
      return emptyBody;
    }

    final listView = ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space3,
      ),
      itemCount: logs.length + 1,
      separatorBuilder: (context, index) {
        if (index == 0) return const VGap.xs();
        return const VGap.sm();
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: VSpacing.space1),
            child: VText(
              'Thời gian: 24 giờ gần đây  ·  Mới nhất trước',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
          );
        }

        final item = logs[index - 1];
        return AuditLogItemCard(
          log: item,
          onTap: () => onItemTap?.call(item),
        );
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        color: colors.primary,
        onRefresh: onRefresh!,
        child: listView,
      );
    }

    return listView;
  }
}
