import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Empty / filtered-empty state cho lịch sử giá riêng (D-04 B & D-08).
class PriceRuleHistoryEmptyView extends StatelessWidget {
  const PriceRuleHistoryEmptyView({
    super.key,
    required this.isFiltered,
    required this.onReset,
    this.onBack,
  });

  final bool isFiltered;
  final VoidCallback onReset;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    if (isFiltered) {
      return Padding(
        padding: const EdgeInsets.all(VSpacing.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VIconBox(
              icon: VIcons.search,
              size: 64,
              iconSize: 32,
              tone: VComponentTone.neutral,
              isCircular: true,
            ),
            const VGap.md(),
            VText(
              'Không tìm thấy lịch sử phù hợp',
              variant: VTextVariant.headingH4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const VGap.xs(),
            VText(
              'Thử điều chỉnh bộ lọc hoặc xóa bớt điều kiện lọc.',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
              textAlign: TextAlign.center,
            ),
            const VGap.lg(),
            VButton(
              label: 'Đặt lại bộ lọc',
              variant: VButtonVariant.outline,
              onPressed: onReset,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(VSpacing.space6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          VIconBox(
            icon: VIcons.history,
            size: 64,
            iconSize: 32,
            tone: VComponentTone.neutral,
            isCircular: true,
          ),
          const VGap.md(),
          VText(
            'Chưa có lịch sử thay đổi',
            variant: VTextVariant.headingH4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const VGap.xs(),
          VText(
            'Giá riêng này chưa phát sinh hoạt động nào.',
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
            textAlign: TextAlign.center,
          ),
          const VGap.lg(),
          if (onBack != null)
            VButton(
              label: 'Quay lại chi tiết',
              variant: VButtonVariant.outline,
              onPressed: onBack,
            ),
        ],
      ),
    );
  }
}

/// Permission / error system state (D-08).
class PriceRuleHistorySystemStateView extends StatelessWidget {
  const PriceRuleHistorySystemStateView({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.description,
    required this.buttonLabel,
    this.onPressed,
  });

  final VIcons icon;
  final VComponentTone tone;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VIconBox(
              icon: icon,
              size: 64,
              iconSize: 32,
              tone: tone,
              isCircular: true,
            ),
            const VGap.md(),
            VText(
              title,
              variant: VTextVariant.headingH4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const VGap.xs(),
            VText(
              description,
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
              textAlign: TextAlign.center,
            ),
            const VGap.lg(),
            if (onPressed != null)
              VButton(
                label: buttonLabel,
                variant: VButtonVariant.outline,
                onPressed: onPressed,
              ),
          ],
        ),
      ),
    );
  }
}

/// Loading skeleton cho timeline lịch sử (D-08).
class PriceRuleHistorySkeletonView extends StatelessWidget {
  const PriceRuleHistorySkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        children: [
          const VSkeleton(width: double.infinity, height: 44),
          const VGap.md(),
          const VSkeleton(width: double.infinity, height: 32),
          const VGap.md(),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, i) => const Padding(
                padding: EdgeInsets.only(bottom: VSpacing.space3),
                child: VSkeleton(width: double.infinity, height: 80),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
