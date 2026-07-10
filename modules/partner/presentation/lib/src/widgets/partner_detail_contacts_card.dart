import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';

import 'partner_detail_expandable_card.dart';

/// Card «Người liên hệ» (org) — tap header để mở/đóng.
class PartnerDetailContactsCard extends StatelessWidget {
  const PartnerDetailContactsCard({
    super.key,
    required this.dto,
    this.onTapViewAll,
    this.initiallyExpanded = false,
  });

  final PartnerDetailDto dto;
  final VoidCallback? onTapViewAll;
  final bool initiallyExpanded;

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
    final contacts = dto.contacts;

    return PartnerDetailExpandableCard(
      title: 'Người liên hệ',
      icon: Icons.people_alt_outlined,
      initiallyExpanded: initiallyExpanded,
      trailingWhenCollapsed: contacts.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${contacts.length}',
                style: VTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      child: contacts.isEmpty
          ? Text(
              'Chưa có người liên hệ.',
              style: VTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            )
          : _ContactsBody(
              contacts: contacts,
              onTapViewAll: onTapViewAll,
              buildStatusTag: _buildStatusTag,
            ),
    );
  }
}

class _ContactsBody extends StatelessWidget {
  const _ContactsBody({
    required this.contacts,
    required this.onTapViewAll,
    required this.buildStatusTag,
  });

  final List<PartnerContactDto> contacts;
  final VoidCallback? onTapViewAll;
  final Widget Function(BuildContext, String, Color) buildStatusTag;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final primaryContact = contacts.firstWhere(
      (c) => c.isPrimary,
      orElse: () => contacts.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colors.surfaceAlt,
              child: Text(
                primaryContact.displayName.trim().isNotEmpty
                    ? primaryContact.displayName.substring(0, 1).toUpperCase()
                    : '?',
                style: VTypography.bodyDefault.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: VSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          primaryContact.displayName,
                          style: VTypography.bodyDefault.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (primaryContact.isPrimary) ...[
                        const SizedBox(width: 8),
                        buildStatusTag(context, 'Chính', colors.success),
                      ],
                    ],
                  ),
                  if (primaryContact.contactRole != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      primaryContact.contactRole!,
                      style: VTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  if (primaryContact.phone != null &&
                      primaryContact.phone!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      primaryContact.phone!,
                      style: VTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (contacts.length > 1 && onTapViewAll != null) ...[
          const SizedBox(height: VSpacing.space3),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onTapViewAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Xem tất cả',
                    style: VTypography.bodyDefault.copyWith(
                      color: colors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: colors.success,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
