import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

enum PartnerContactAction { edit, setPrimary, remove }

Future<PartnerContactAction?> showPartnerContactActionSheet(
  BuildContext context, {
  required PartnerContactDto contact,
}) {
  return showVBottomSheet<PartnerContactAction>(
    context: context,
    child: PartnerContactActionSheet(contact: contact),
  );
}

class PartnerContactActionSheet extends StatelessWidget {
  const PartnerContactActionSheet({
    super.key,
    required this.contact,
  });

  final PartnerContactDto contact;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Material(
      color: colors.surface.withValues(alpha: 0),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VSpacing.space4,
                  VSpacing.space4,
                  VSpacing.space4,
                  VSpacing.space2,
                ),
                child: VText(
                  'Thao tác',
                  variant: VTextVariant.headingH3,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: VSpacing.space2),
              Divider(color: colors.borderDefault, height: 1),
              ListTile(
                leading: VIcon(icon: VIcons.edit, color: colors.textSecondary),
                title: VText(
                  'Chỉnh sửa liên hệ',
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: VIcon(icon: VIcons.chevronRight, color: colors.textMuted),
                onTap: () => Navigator.of(context).pop(PartnerContactAction.edit),
              ),
              if (!contact.isPrimary && contact.status == PartnerStatus.active)
                ListTile(
                  leading: VIcon(icon: VIcons.star, color: colors.textSecondary),
                  title: VText(
                    'Đặt làm chính',
                    color: colors.textPrimary,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: VIcon(icon: VIcons.chevronRight, color: colors.textMuted),
                  onTap: () => Navigator.of(context).pop(PartnerContactAction.setPrimary),
                ),
              ListTile(
                leading: VIcon(icon: VIcons.delete, color: colors.danger),
                title: VText(
                  'Gỡ khỏi tổ chức',
                  color: colors.danger,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: VIcon(icon: VIcons.chevronRight, color: colors.danger),
                onTap: () => Navigator.of(context).pop(PartnerContactAction.remove),
              ),
              const SizedBox(height: VSpacing.space2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
                child: VButton(
                  label: 'Hủy',
                  variant: VButtonVariant.outline,
                  foregroundColor: colors.textPrimary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: VSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }
}
