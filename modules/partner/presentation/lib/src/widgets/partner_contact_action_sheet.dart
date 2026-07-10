import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';

enum PartnerContactAction { edit, setPrimary, remove }

class PartnerContactActionSheet extends StatelessWidget {
  const PartnerContactActionSheet({
    super.key,
    required this.contact,
    required this.onActionSelected,
  });

  final PartnerContactDto contact;
  final ValueChanged<PartnerContactAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VBottomSheet(
      child: Material(
        color: Colors.transparent,
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
                  child: Text(
                    'Thao tác',
                    style: VTypography.headingH3.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: VSpacing.space2),
                Divider(color: colors.borderDefault, height: 1),
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: colors.textSecondary),
                  title: Text(
                    'Chỉnh sửa liên hệ',
                    style: VTypography.bodyDefault.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                  onTap: () {
                    Navigator.of(context).pop();
                    onActionSelected(PartnerContactAction.edit);
                  },
                ),
                if (!contact.isPrimary)
                  ListTile(
                    leading: Icon(Icons.star_outline_rounded, color: colors.textSecondary),
                    title: Text(
                      'Đặt làm chính',
                      style: VTypography.bodyDefault.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                    onTap: () {
                      Navigator.of(context).pop();
                      onActionSelected(PartnerContactAction.setPrimary);
                    },
                  ),
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: colors.danger),
                  title: Text(
                    'Gỡ khỏi tổ chức',
                    style: VTypography.bodyDefault.copyWith(
                      color: colors.danger,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: colors.danger),
                  onTap: () {
                    Navigator.of(context).pop();
                    onActionSelected(PartnerContactAction.remove);
                  },
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
      ),
    );
  }
}
