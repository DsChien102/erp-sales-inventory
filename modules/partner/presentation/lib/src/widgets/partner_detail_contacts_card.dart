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
                borderRadius: BorderRadius.circular(VRadius.r8),
              ),
              child: VText(
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
                borderRadius: BorderRadius.circular(VRadius.r8),
              ),
              child: VText(
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
              child: VText(
                'Chưa có người liên hệ.',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
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
                  padding: const EdgeInsets.symmetric(vertical: VSpacing.space1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VIcon(
                        icon: VIcons.addCircle,
                        size: 16,
                        color: colors.success,
                      ),
                      const SizedBox(width: VSpacing.space1),
                      VText(
                        'Thêm người liên hệ',
                        variant: VTextVariant.bodyDefault,
                        color: colors.success,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              if (onTapViewAll != null)
                InkWell(
                  onTap: onTapViewAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: VSpacing.space1),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VText(
                          contacts.isEmpty ? 'Tất cả' : 'Xem tất cả (${contacts.length})',
                          color: colors.success,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const VGap.horizontalXs(),
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

  Widget _buildStatusTag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(VRadius.r4),
      ),
      child: VText(
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
              VAvatar(name: displayContacts[i].displayName, textSize: 14),
              const SizedBox(width: VSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: VText(
                            displayContacts[i].displayName,
                            variant: VTextVariant.bodyDefault,
                            color: colors.textPrimary,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (displayContacts[i].isPrimary) ...[
                          const SizedBox(width: VSpacing.space2),
                          _buildStatusTag(context, 'Chính', colors.success),
                        ],
                        if (displayContacts[i].status == PartnerStatus.inactive) ...[
                          const SizedBox(width: VSpacing.space2),
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
                      const VGap.xs(),
                      VText(
                        displayContacts[i].contactRole!,
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    ],
                    if (displayContacts[i].phone != null &&
                        displayContacts[i].phone!.isNotEmpty) ...[
                      const VGap.xs(),
                      VText(
                        displayContacts[i].phone!,
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    ],
                    if (displayContacts[i].email != null &&
                        displayContacts[i].email!.isNotEmpty) ...[
                      const VGap.xs(),
                      VText(
                        displayContacts[i].email!,
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
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
