import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

enum PartnerDeletePrimaryContactBlockedAction { close, viewOrganization }

Future<PartnerDeletePrimaryContactBlockedAction?> showPartnerDeletePrimaryContactBlockedSheet(
  BuildContext context, {
  required String organizationName,
}) {
  return showVAdaptiveSheet<PartnerDeletePrimaryContactBlockedAction>(
    context: context,
    child: PartnerDeletePrimaryContactBlockedSheet(
      organizationName: organizationName,
    ),
  );
}

class PartnerDeletePrimaryContactBlockedSheet extends StatelessWidget {
  const PartnerDeletePrimaryContactBlockedSheet({
    super.key,
    required this.organizationName,
  });

  final String organizationName;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return SafeArea(
      top: false,
      child: Padding(
        key: const Key('delete_primary_contact_blocked_sheet'),
        padding: const EdgeInsets.fromLTRB(
          VSpacing.space4,
          VSpacing.space2,
          VSpacing.space4,
          VSpacing.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: VSpacing.space5),
            VIcon(icon: VIcons.delete, size: 44, color: colors.danger),
            const SizedBox(height: VSpacing.space3),
            VText(
              'Không thể xóa hồ sơ',
              variant: VTextVariant.headingH3,
              color: colors.textPrimary,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const VGap.sm(),
            VText(
              'Hồ sơ này đang là người liên hệ chính của “$organizationName”. '
              'Hãy đổi hoặc gỡ người liên hệ chính trước khi xóa hồ sơ.',
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.4),
            ),
            const VGap.md(),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    key: const Key('delete_blocked_close'),
                    label: 'Đóng',
                    variant: VButtonVariant.secondary,
                    foregroundColor: colors.success,
                    onPressed: () => Navigator.of(context).pop(
                      PartnerDeletePrimaryContactBlockedAction.close,
                    ),
                  ),
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: VButton(
                    key: const Key('delete_blocked_view_organization'),
                    label: 'Xem tổ chức',
                    onPressed: () => Navigator.of(context).pop(
                      PartnerDeletePrimaryContactBlockedAction.viewOrganization,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
