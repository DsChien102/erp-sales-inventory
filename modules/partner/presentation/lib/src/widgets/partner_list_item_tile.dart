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

  String _getInitials(String displayName) {
    final words = displayName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words[0].isEmpty) return '?';
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return '${words[0].substring(0, 1)}${words.last.substring(0, 1)}'.toUpperCase();
  }

  Color _getAvatarColor(String displayName) {
    final palette = [
      VColors.success,
      VColors.warning,
      VColors.info,
      VColors.primary,
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
    ];
    int sum = 0;
    for (int i = 0; i < displayName.length; i++) {
      sum += displayName.codeUnitAt(i);
    }
    return palette[sum % palette.length];
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final initials = _getInitials(item.displayName);
    final avatarColor = _getAvatarColor(item.displayName);

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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: VTypography.bodyDefault.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: VSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.displayName,
                          style: VTypography.bodyDefault.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.status == PartnerStatus.active)
                        _StatusBadge(
                          label: 'Đang hoạt động',
                          color: VColors.success,
                        )
                      else if (item.status == PartnerStatus.inactive)
                        _StatusBadge(
                          label: 'Ngừng hoạt động',
                          color: VColors.warning,
                        ),
                    ],
                  ),
                  const SizedBox(height: VSpacing.space1),
                  Text(
                    _subtitle(item),
                    style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                  ),
                  if (item.phone != null && item.phone!.isNotEmpty) ...[
                    const SizedBox(height: VSpacing.space1),
                    Text(
                      item.phone!,
                      style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                    ),
                  ],
                  if (item.taxCode != null && item.taxCode!.isNotEmpty) ...[
                    const SizedBox(height: VSpacing.space1),
                    Text(
                      'MST ${item.taxCode}',
                      style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                    ),
                  ],
                  if (item.updatedAt != null) ...[
                    const SizedBox(height: VSpacing.space1),
                    Text(
                      'Cập nhật ${_formatDate(item.updatedAt!)}',
                      style: VTypography.bodySmall.copyWith(color: colors.textMuted),
                    ),
                  ]
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
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
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

