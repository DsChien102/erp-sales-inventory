import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

class PartnerListItemTile extends StatelessWidget {
  const PartnerListItemTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  final PartnerListItemDto item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(VSpacing.space4),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.borderDefault)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VIconBox(
              iconData: item.partnerType == PartnerType.person
                  ? Icons.person_outline
                  : Icons.apartment_outlined,
              size: 40,
              backgroundColor: colors.surfaceBrand,
              iconColor: colors.primary,
            ),
            const SizedBox(width: VSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    style: VTypography.bodyDefault.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: VSpacing.space1),
                  Text(
                    _subtitle(item),
                    style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                  ),
                  if (item.phone != null) ...[
                    const SizedBox(height: VSpacing.space1),
                    Text(
                      item.phone!,
                      style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const VIcon(iconData: Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  static String _subtitle(PartnerListItemDto item) {
    final typeLabel = item.partnerType == PartnerType.person ? 'Cá nhân' : 'Tổ chức';
    final roleLabel = _roleLabel(item.roles);
    return '$typeLabel · $roleLabel';
  }

  static String _roleLabel(List<PartnerRoleType> roles) {
    if (roles.length >= 2) return 'KH & NCC';
    if (roles.contains(PartnerRoleType.customer)) return 'Khách hàng';
    if (roles.contains(PartnerRoleType.supplier)) return 'Nhà cung cấp';
    return 'Chưa có vai trò';
  }
}
