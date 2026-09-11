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

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space4,
          vertical: VSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(VRadius.card),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VAvatar(name: item.displayName, textSize: 14),
            const SizedBox(width: VSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: VText(
                          item.displayName,
                          variant: VTextVariant.bodyDefault,
                          color: colors.textPrimary,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.status == PartnerStatus.active)
                        _StatusBadge(
                          label: 'Đang hoạt động',
                          color: colors.success,
                        )
                      else if (item.status == PartnerStatus.inactive)
                        _StatusBadge(
                          label: 'Ngừng hoạt động',
                          color: colors.warning,
                        ),
                    ],
                  ),
                  const SizedBox(height: VSpacing.space1),
                  VText(
                    _subtitle(item),
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                  if (item.phone != null && item.phone!.isNotEmpty) ...[
                    const SizedBox(height: VSpacing.space1),
                    VText(
                      item.phone!,
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                  ],
                  if (item.taxCode != null && item.taxCode!.isNotEmpty) ...[
                    const SizedBox(height: VSpacing.space1),
                    VText(
                      'MST ${item.taxCode}',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                  ],
                  if (item.updatedAt != null) ...[
                    const SizedBox(height: VSpacing.space1),
                    VText(
                      'Cập nhật ${_formatDate(item.updatedAt!)}',
                      variant: VTextVariant.bodySmall,
                      color: colors.textMuted,
                    ),
                  ],
                ],
              ),
            ),
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
    if (roles.contains(PartnerRoleType.customer) && roles.contains(PartnerRoleType.supplier)) {
      return 'KH & NCC';
    }
    if (roles.contains(PartnerRoleType.customer)) return 'Khách hàng';
    if (roles.contains(PartnerRoleType.supplier)) return 'Nhà cung cấp';
    return 'Chưa có vai trò';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(VRadius.r4),
      ),
      child: VText(
        label,
        style: VTypography.bodySmall.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
