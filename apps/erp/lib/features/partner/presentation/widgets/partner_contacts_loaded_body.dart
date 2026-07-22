import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

import 'partner_contact_empty_illustration.dart';
import 'partner_contact_tile.dart';

class PartnerContactsLoadedBody extends StatelessWidget {
  const PartnerContactsLoadedBody({
    super.key,
    required this.organization,
    required this.filteredContacts,
    required this.onSearch,
    required this.onAddContact,
    required this.onContactTap,
  });

  final PartnerDetailDto organization;
  final List<PartnerContactDto> filteredContacts;
  final ValueChanged<String> onSearch;
  final VoidCallback onAddContact;
  final ValueChanged<PartnerContactDto> onContactTap;

  String get _rolesLabel {
    final roles = organization.roles;
    final isCustomer = roles.contains(PartnerRoleType.customer);
    final isSupplier = roles.contains(PartnerRoleType.supplier);
    if (isCustomer && isSupplier) return 'KH & NCC';
    if (isCustomer) return 'Khách hàng';
    return 'Nhà cung cấp';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.space4,
            VSpacing.space4,
            VSpacing.space4,
            VSpacing.space2,
          ),
          child: Container(
            padding: const EdgeInsets.all(VSpacing.space4),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(VRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VText(
                  organization.displayName,
                  variant: VTextVariant.headingH3,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.xs(),
                VText(
                  'Tổ chức • $_rolesLabel',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (organization.contacts.isEmpty)
          Expanded(
            child: VPagePadding(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const PartnerContactEmptyIllustration(),
                  const VGap.lg(),
                  VText(
                    'Chưa có người liên hệ',
                    variant: VTextVariant.headingH3,
                    color: colors.textPrimary,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const VGap.sm(),
                  VText(
                    'Thêm người liên hệ để liên kết làm việc\nvới tổ chức này.',
                    variant: VTextVariant.bodyDefault,
                    color: colors.textSecondary,
                    textAlign: TextAlign.center,
                  ),
                  const VGap.md(),
                  VButton(
                    label: 'Gợi ý thêm người liên hệ',
                    variant: VButtonVariant.outline,
                    foregroundColor: colors.success,
                    onPressed: onAddContact,
                  ),
                ],
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: VSearchBar(
              key: const Key('input_contact_search'),
              hintText: 'Tìm kiếm người liên hệ',
              onChanged: onSearch,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
            child: VText(
              '${filteredContacts.length} người liên hệ',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const VGap.sm(),
          Expanded(
            child: ListView.separated(
              key: const Key('list_contacts_view'),
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
              itemCount: filteredContacts.length,
              separatorBuilder: (_, _) =>
                  Divider(color: colors.borderDefault, height: 1),
              itemBuilder: (context, index) {
                final contact = filteredContacts[index];
                return PartnerContactTile(
                  contact: contact,
                  onTap: () => onContactTap(contact),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
