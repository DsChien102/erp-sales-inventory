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

  String _formatDate(DateTime date) => VDateTime.date(date);

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: VSpacing.space3,
        children: [
          VAvatar(name: item.displayName, textSize: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  item.displayName,
                  variant: VTextVariant.bodyDefault,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const VGap(VSpacing.space1),
                VText(
                  _subtitle(item),
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
                if (item.phone != null && item.phone!.isNotEmpty) ...[
                  const VGap(VSpacing.space1),
                  VText(
                    item.phone!,
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ],
                if (item.taxCode != null && item.taxCode!.isNotEmpty) ...[
                  const VGap(VSpacing.space1),
                  VText(
                    'MST ${item.taxCode}',
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ],
                if (item.updatedAt != null) ...[
                  const VGap(VSpacing.space1),
                  VText(
                    'Cập nhật ${_formatDate(item.updatedAt!)}',
                    variant: VTextVariant.bodySmall,
                    color: colors.textMuted,
                  ),
                ],
              ],
            ),
          ),
          if (item.status == PartnerStatus.active)
            const VBadge(
              label: 'Đang hoạt động',
              tone: VComponentTone.success,
            )
          else if (item.status == PartnerStatus.inactive)
            const VBadge(
              label: 'Ngừng hoạt động',
              tone: VComponentTone.warning,
              isSmall: true,
            ),
        ],
      ),
    );
  }

  static String _subtitle(PartnerListItemDto item) {
    final typeLabel = item.partnerType == PartnerType.person ? 'Cá nhân' : 'Tổ chức';
    final roleLabel = _roleLabel(item.roles);
    return '$typeLabel · $roleLabel';
  }

  static String _roleLabel(List<PartnerRoleType> roles) {
    if (roles.contains(PartnerRoleType.customer) && roles.contains(PartnerRoleType.supplier)) {
      return 'KH & NCC';
    }
    if (roles.contains(PartnerRoleType.customer)) return 'Khách hàng';
    if (roles.contains(PartnerRoleType.supplier)) return 'Nhà cung cấp';
    return 'Chưa có vai trò';
  }
}
