import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';

class PartnerDetailContactsCard extends StatelessWidget {
  const PartnerDetailContactsCard({
    super.key,
    required this.dto,
    required this.onTapHeader,
    required this.onTapViewAll,
  });

  final PartnerDetailDto dto;
  final VoidCallback onTapHeader;
  final VoidCallback onTapViewAll;

  Widget _buildStatusTag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: VTypography.bodySmall.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    if (dto.contacts.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(VRadius.card),
          border: Border.all(color: colors.borderDefault),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: VSpacing.space4, vertical: 0),
          leading: Icon(Icons.people_alt_outlined, color: colors.textSecondary, size: 20),
          title: Text(
            'Người liên hệ',
            style: VTypography.bodyDefault.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: colors.textMuted),
          onTap: onTapHeader,
        ),
      );
    }

    final primaryContact = dto.contacts.firstWhere(
      (c) => c.isPrimary,
      orElse: () => dto.contacts.first,
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: VSpacing.space4, vertical: 0),
            leading: Icon(Icons.people_alt_outlined, color: colors.textSecondary, size: 20),
            title: Text(
              'Người liên hệ',
              style: VTypography.bodyDefault.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${dto.contacts.length}',
                    style: VTypography.bodySmall.copyWith(
                      color: colors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: colors.textMuted),
              ],
            ),
            onTap: onTapHeader,
          ),
          Divider(color: colors.borderDefault, height: 1),
          Padding(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.surfaceAlt,
                  child: Text(
                    primaryContact.displayName.trim().isNotEmpty
                        ? primaryContact.displayName.substring(0, 1).toUpperCase()
                        : '?',
                    style: VTypography.bodyDefault.copyWith(fontWeight: FontWeight.w600, color: colors.textPrimary),
                  ),
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            primaryContact.displayName,
                            style: VTypography.bodyDefault.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (primaryContact.isPrimary) ...[
                            const SizedBox(width: 8),
                            _buildStatusTag(context, 'Chính', colors.success),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (primaryContact.contactRole != null)
                        Text(
                          primaryContact.contactRole!,
                          style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                        ),
                      if (primaryContact.phone != null && primaryContact.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          primaryContact.phone!,
                          style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (dto.contacts.length > 1) ...[
            Divider(color: colors.borderDefault, height: 1),
            InkWell(
              onTap: onTapViewAll,
              child: Padding(
                padding: const EdgeInsets.only(right: VSpacing.space4, bottom: VSpacing.space3, top: VSpacing.space3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Xem tất cả',
                      style: VTypography.bodyDefault.copyWith(
                        color: colors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 16, color: colors.success),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
