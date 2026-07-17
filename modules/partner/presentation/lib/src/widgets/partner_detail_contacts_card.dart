import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

import 'partner_detail_expandable_card.dart';

/// Card «Người liên hệ» (org) — preview + thêm / xem tất cả (S5).
class PartnerDetailContactsCard extends StatelessWidget {
  const PartnerDetailContactsCard({
    super.key,
    required this.dto,
    this.onTapAdd,
    this.onTapViewAll,
    this.initiallyExpanded = false,
  });

  final PartnerDetailDto dto;
  final VoidCallback? onTapAdd;
  final VoidCallback? onTapViewAll;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final contacts = dto.contacts;

    return PartnerDetailExpandableCard(
      title: 'Người liên hệ',
      icon: VIcons.people,
      initiallyExpanded: initiallyExpanded,
      trailingWhenCollapsed: contacts.isEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Chưa có',
                style: VTypography.bodySmall.copyWith(
                  color: colors.warning,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.space2),
              child: Text(
                'Chưa có người liên hệ.',
                style: VTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            )
          else
            _ContactsListBody(
              contacts: contacts,
              colors: colors,
            ),
          const SizedBox(height: VSpacing.space3),
          Divider(color: colors.borderDefault, height: 1),
          const SizedBox(height: VSpacing.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: onTapAdd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VIcon(
                        icon: VIcons.addCircle,
                        size: 16,
                        color: colors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Thêm người liên hệ',
                        style: VTypography.bodyDefault.copyWith(
                          color: colors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (onTapViewAll != null)
                InkWell(
                  onTap: onTapViewAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          contacts.isEmpty ? 'Tất cả' : 'Xem tất cả (${contacts.length})',
                          style: VTypography.bodyDefault.copyWith(
                            color: colors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        VIcon(
                          icon: VIcons.chevronRight,
                          size: 16,
                          color: colors.success,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactsListBody extends StatelessWidget {
  const _ContactsListBody({
    required this.contacts,
    required this.colors,
  });

  final List<PartnerContactDto> contacts;
  final VColorScheme colors;

  Color _getAvatarColor(String displayName) {
    final palette = [
      VColors.success,
      VColors.warning,
      VColors.info,
      VColors.primary,
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
    ];
    var sum = 0;
    for (var i = 0; i < displayName.length; i++) {
      sum += displayName.codeUnitAt(i);
    }
    return palette[sum % palette.length];
  }

  String _getInitials(String displayName) {
    final words = displayName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) {
      return words.first[0].toUpperCase();
    }
    final first = words.first[0].toUpperCase();
    final last = words.last[0].toUpperCase();
    return '$first$last';
  }

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
    final sorted = List<PartnerContactDto>.from(contacts)
      ..sort((a, b) => (b.isPrimary ? 1 : 0).compareTo(a.isPrimary ? 1 : 0));
    final displayContacts = sorted.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < displayContacts.length; i++) ...[
          if (i > 0) const SizedBox(height: VSpacing.space3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _getAvatarColor(displayContacts[i].displayName),
                child: Text(
                  _getInitials(displayContacts[i].displayName),
                  style: VTypography.bodyDefault.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
                            displayContacts[i].displayName,
                            style: VTypography.bodyDefault.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (displayContacts[i].isPrimary) ...[
                          const SizedBox(width: 8),
                          _buildStatusTag(context, 'Chính', colors.success),
                        ],
                        if (displayContacts[i].status == PartnerStatus.inactive) ...[
                          const SizedBox(width: 8),
                          _buildStatusTag(
                            context,
                            'Ngừng hoạt động',
                            colors.warning,
                          ),
                        ],
                      ],
                    ),
                    if (displayContacts[i].contactRole != null &&
                        displayContacts[i].contactRole!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        displayContacts[i].contactRole!,
                        style: VTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    if (displayContacts[i].phone != null &&
                        displayContacts[i].phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        displayContacts[i].phone!,
                        style: VTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    if (displayContacts[i].email != null &&
                        displayContacts[i].email!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        displayContacts[i].email!,
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
        ],
      ],
    );
  }
}
