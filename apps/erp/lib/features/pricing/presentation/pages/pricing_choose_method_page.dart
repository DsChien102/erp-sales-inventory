import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

/// S4 — Chọn phương thức thêm giá riêng (SG-03 D-01).
class PricingChooseMethodPage extends StatelessWidget {
  const PricingChooseMethodPage({
    super.key,
    this.canCreate = true,
    this.canImport = true,
  });

  final bool canCreate;
  final bool canImport;

  @override
  Widget build(BuildContext context) {
    return VPageScaffold(
      key: const Key('wgt_e02_u02_fr01_01'),
      title: 'Thêm giá riêng',
      showBackButton: true,
      body: VPagePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const VGap.lg(),
            VText('Chọn cách thêm', variant: VTextVariant.headingH4),
            const VGap.sm(),
            VText(
              'Bạn muốn tạo giá riêng theo cách nào?',
              variant: VTextVariant.bodyDefault,
              color: context.vColors.textSecondary,
            ),
            const VGap.lg(),
            if (canCreate)
              _MethodCard(
                icon: VIcons.addCircle,
                title: 'Tạo thủ công',
                description: 'Nhập thông tin giá riêng cho từng khách hàng.',
                onTap: () => context.push('/pricing/new'),
              ),
            if (canCreate && canImport) const VGap.md(),
            if (canImport)
              _MethodCard(
                icon: VIcons.download,
                title: 'Nhập từ Excel',
                description:
                    'Tạo nhiều giá riêng cùng lúc bằng file Excel mẫu.',
                onTap: () => context.push('/pricing/import'),
              ),
            if (!canCreate && !canImport) ...[
              const VEmptyState(
                icon: VIcons.shield,
                title: 'Không có quyền',
                description: 'Bạn không có quyền tạo hoặc nhập giá riêng.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final VIcons icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VCard(
      onTap: onTap,
      child: Row(
        children: [
          VIconBox(
            icon: icon,
            size: 44,
            iconSize: 22,
            tone: VComponentTone.primary,
            borderRadius: VRadius.r12,
          ),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(title, variant: VTextVariant.headingH4),
                const VGap.xs(),
                VText(
                  description,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          VIcon(
            icon: VIcons.chevronRight,
            color: colors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}
