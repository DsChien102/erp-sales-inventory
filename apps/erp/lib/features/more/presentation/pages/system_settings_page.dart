import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

class SystemSettingsPage extends StatelessWidget {
  const SystemSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VPageScaffold(
      title: 'Thiết lập',
      showBackButton: true,
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space4,
        ),
        children: [
          VCard(
            onTap: () => context.push('/more/einvoice-settings'),
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space4,
              vertical: VSpacing.space3 + 2,
            ),
            child: Row(
              children: [
                VIconBox(
                  icon: VIcons.description,
                  size: 44,
                  iconSize: 20,
                  backgroundColor: colors.surfaceBrand,
                  iconColor: colors.primary,
                  borderRadius: VRadius.r12,
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Thiết lập hóa đơn điện tử',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VTypography.headingH4.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Kết nối, chọn mẫu hóa đơn, cấu hình tự động phát hành và gửi HĐĐT',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: VTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                VIcon(
                  icon: VIcons.chevronRight,
                  color: colors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.space3),
          VCard(
            onTap: () => context.push('/more/product-settings'),
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space4,
              vertical: VSpacing.space3 + 2,
            ),
            child: Row(
              children: [
                VIconBox(
                  icon: VIcons.inventory,
                  size: 44,
                  iconSize: 20,
                  backgroundColor: colors.surfaceBrand,
                  iconColor: colors.primary,
                  borderRadius: VRadius.r12,
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sản phẩm',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VTypography.headingH4.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Giá bán, nhóm thông tin và trường tuỳ biến cho sản phẩm',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: VTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                VIcon(
                  icon: VIcons.chevronRight,
                  color: colors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
