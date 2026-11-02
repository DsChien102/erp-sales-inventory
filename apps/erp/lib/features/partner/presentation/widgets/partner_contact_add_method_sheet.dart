import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

enum AddContactMethod { createNew, selectExisting }

Future<AddContactMethod?> showPartnerContactAddMethodSheet(
  BuildContext context,
) {
  return showVAdaptiveSheet<AddContactMethod>(
    context: context,
    child: const PartnerContactAddMethodSheet(),
  );
}

class PartnerContactAddMethodSheet extends StatelessWidget {
  const PartnerContactAddMethodSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VPagePadding(
      applyBottomSafeArea: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const VGap.sm(),
            VText(
              'Thêm người liên hệ',
              variant: VTextVariant.headingH3,
              color: colors.textPrimary,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const VGap.md(),
            // Option 1: Tạo người liên hệ mới (Card style)
            VCard(
              onTap: () => Navigator.of(context).pop(AddContactMethod.createNew),
              child: Row(
                children: [
                  VIconBox(
                    backgroundColor: colors.successBg,
                    icon: VIcons.personAdd,
                    iconColor: colors.success,
                    isCircular: true,
                  ),
                  const VGap.horizontalMd(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VText(
                          'Tạo người liên hệ mới',
                          color: colors.textPrimary,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const VGap.xs(),
                        VText(
                          'Nhập thông tin để tạo người liên hệ mới',
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const VGap.horizontalSm(),
                  VIcon(icon: VIcons.chevronRight, color: colors.textMuted),
                ],
              ),
            ),

            // Option 2: Chọn từ cá nhân có sẵn (Card style)
            const VGap.sm(),
            VCard(
              onTap: () => Navigator.of(context).pop(AddContactMethod.selectExisting),
              child: Row(
                children: [
                  VIconBox(
                    backgroundColor: colors.infoBg,
                    icon: VIcons.search,
                    iconColor: colors.info,
                    isCircular: true,
                  ),
                  const VGap.horizontalMd(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VText(
                          'Chọn từ cá nhân có sẵn',
                          color: colors.textPrimary,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const VGap.xs(),
                        VText(
                          'Tìm kiếm và liên kết cá nhân đã có trong hệ thống',
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const VGap.horizontalMd(),
                  VIcon(icon: VIcons.chevronRight, color: colors.textMuted),
                ],
              ),
            ),
            const VGap.md(),
            VButton(
              label: 'Hủy',
              variant: VButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
