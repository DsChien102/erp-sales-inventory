import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class OrganizationsPage extends StatelessWidget {
  const OrganizationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Column(
      children: [
        // Search bar & Filter button row
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.screenMobile,
            vertical: VSpacing.space2,
          ),
          child: Row(
            children: [
              const Expanded(
                child: VSearchBar(
                  hintText: 'Tìm tên hoặc mã tổ chức',
                ),
              ),
              const VGap.horizontalSm(),
              VIconBox(
                icon: VIcons.tune,
                size: 44,
                iconSize: 20,
                backgroundColor: colors.surface,
                iconColor: colors.textPrimary,
                borderColor: colors.borderDefault,
                borderRadius: VRadius.button,
                onTap: () {},
              ),
            ],
          ),
        ),

        // Horizontal filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.screenMobile,
            vertical: VSpacing.space1,
          ),
          child: Row(
            children: [
              const VChip(
                label: 'Tất cả',
                selected: true,
              ),
              const VGap.horizontalSm(),
              VChip(
                label: 'Thiết lập',
                selected: false,
                onTap: () {},
              ),
              const VGap.horizontalSm(),
              VChip(
                label: 'Hoạt động',
                selected: false,
                onTap: () {},
              ),
              const VGap.horizontalSm(),
              VChip(
                label: 'Tạm ngừng',
                selected: false,
                onTap: () {},
              ),
            ],
          ),
        ),

        // Body placeholder
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.screenMobile,
              vertical: VSpacing.space3,
            ),
            children: [
              VCard(
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        'Danh sách tổ chức',
                        style: VTypography.bodyDefault.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const VGap.xs(),
                      VText(
                        'Danh sách các tổ chức/phòng khám trong hệ thống sẽ hiển thị ở đây.',
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
