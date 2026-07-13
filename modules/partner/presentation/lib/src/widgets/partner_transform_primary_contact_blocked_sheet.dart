import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

enum PartnerTransformPrimaryContactBlockedAction { close, viewOrganization }

class PartnerTransformPrimaryContactBlockedSheet extends StatelessWidget {
  const PartnerTransformPrimaryContactBlockedSheet({
    super.key,
    required this.organizationName,
  });

  final String organizationName;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return SafeArea(
      top: false,
      child: Container(
        key: const Key('transform_primary_contact_blocked_sheet'),
        padding: const EdgeInsets.fromLTRB(
          VSpacing.space4,
          VSpacing.space2,
          VSpacing.space4,
          VSpacing.space4,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
            Icon(Icons.apartment_rounded, size: 44, color: colors.warning),
            const SizedBox(height: VSpacing.space3),
            Text(
              'Không thể chuyển thành tổ chức',
              style: VTypography.headingH3.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VSpacing.space2),
            Text(
              'Khách hàng này đang là người liên hệ chính của “$organizationName”. '
              'Hãy đổi người liên hệ chính của tổ chức trước khi thực hiện chuyển đổi.',
              style: VTypography.bodyDefault.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VSpacing.space5),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    key: const Key('transform_blocked_close'),
                    label: 'Đóng',
                    variant: VButtonVariant.outline,
                    foregroundColor: colors.success,
                    onPressed: () => Navigator.of(context).pop(
                      PartnerTransformPrimaryContactBlockedAction.close,
                    ),
                  ),
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: VButton(
                    key: const Key('transform_blocked_view_organization'),
                    label: 'Xem tổ chức',
                    onPressed: () => Navigator.of(context).pop(
                      PartnerTransformPrimaryContactBlockedAction.viewOrganization,
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
