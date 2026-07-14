import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductSettingsPage extends StatelessWidget {
  const ProductSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: const VAppBar(
        title: 'Sản phẩm',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space4,
        ),
        children: [
          VCard(
            onTap: () {
              context.push('/more/product-settings/store-price-rule');
            },
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space4,
              vertical: VSpacing.space3 + 2,
            ),
            child: Row(
              children: [
                VIconBox(
                  iconData: Icons.local_offer_outlined,
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
                        'Giá sàn & Giá niêm yết',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VTypography.headingH4.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Cấu hình khung giá cửa hàng dùng làm mặc định khi định giá sản phẩm',
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
                Icon(
                  Icons.chevron_right,
                  color: colors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.space3),
          VCard(
            onTap: () => context.push('/more/product-settings/custom-fields'),
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space4,
              vertical: VSpacing.space3 + 2,
            ),
            child: Row(
              children: [
                VIconBox(
                  iconData: Icons.view_list_outlined,
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
                        'Nhóm & trường thông tin',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VTypography.headingH4.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Cấu hình các nhóm và trường thông tin bổ sung cho sản phẩm',
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
                Icon(
                  Icons.chevron_right,
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
