import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

class PartnerContactTile extends StatelessWidget {
  const PartnerContactTile({
    super.key,
    required this.contact,
    required this.onTap,
  });

  final PartnerContactDto contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: VSpacing.space3),
        child: Row(
          children: [
            VAvatar(name: contact.displayName, textSize: 14),
            const VGap.horizontalSm(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: VText(
                          contact.displayName,
                          variant: VTextVariant.bodyDefault,
                          color: colors.textPrimary,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (contact.isPrimary) ...[
                        const VGap.horizontalSm(),
                        _StatusChip(
                          label: 'Chính',
                          foreground: colors.success,
                          background: colors.success.withValues(alpha: 0.1),
                        ),
                      ],
                      if (contact.status == PartnerStatus.inactive) ...[
                        const VGap.horizontalSm(),
                        _StatusChip(
                          label: 'Ngừng hoạt động',
                          foreground: colors.warning,
                          background: colors.warning.withValues(alpha: 0.1),
                        ),
                      ],
                    ],
                  ),
                  if (contact.contactRole != null &&
                      contact.contactRole!.isNotEmpty) ...[
                    const SizedBox(height: VSpacing.space1),
                    VText(
                      contact.contactRole!,
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                  ],
                  if (contact.phone != null && contact.phone!.isNotEmpty) ...[
                    const SizedBox(height: VSpacing.space1),
                    VText(
                      contact.phone!,
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                  ],
                  if (contact.email != null && contact.email!.isNotEmpty) ...[
                    const SizedBox(height: VSpacing.space1),
                    VText(
                      contact.email!,
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
            const VGap.horizontalSm(),
            Icon(Icons.chevron_right_rounded, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space2,
        vertical: VSpacing.space1 / 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(VRadius.r4),
      ),
      child: VText(
        label,
        variant: VTextVariant.caption,
        color: foreground,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
