import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

class ReceiptEntryChoicePage extends StatelessWidget {
  const ReceiptEntryChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Scaffold(
      backgroundColor: colors.surfaceAlt,
      appBar: const VAppBar(
        title: 'Nhận hàng',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Chứng từ mua chưa có (SCR-007 thuộc T7-0d): thẻ tạm khoá kèm lý do.
            const _ChoiceCard(
              title: 'Nhận theo chứng từ',
              subtitle: 'Chưa có chứng từ mua chờ nhận.',
              icon: VIcons.receipt,
              enabled: false,
            ),
            const VGap(VSpacing.space3),
            _ChoiceCard(
              title: 'Nhập hàng nhanh',
              subtitle: 'Hàng đã đến, chưa có chứng từ mua.',
              icon: VIcons.inventory,
              onTap: () => context.push('/warehouse/receipts/quick/header'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final VIcons icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: IgnorePointer(
        ignoring: !enabled,
        child: VCard(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Row(
              children: [
                VCardIcon(icon: icon, tone: VComponentTone.neutral),
                const VGap(VSpacing.space3, axis: Axis.horizontal),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        title,
                        style: VTypography.labelDefault.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const VGap(VSpacing.space1),
                      VText(
                        subtitle,
                        style: VTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const VGap(VSpacing.space2, axis: Axis.horizontal),
                const VIcon(
                  icon: VIcons.chevronRight,
                  iconSize: VIconSize.sm,
                  iconColor: VIconColor.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
