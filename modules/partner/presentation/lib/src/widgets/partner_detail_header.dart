import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

/// Detail header: avatar, name, type/role, status badge.
class PartnerDetailHeader extends StatelessWidget {
  const PartnerDetailHeader({super.key, required this.dto});

  final PartnerDetailDto dto;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isPerson = dto.partnerType == PartnerType.person;
    final labelType = isPerson ? 'Cá nhân' : 'Tổ chức';
    final isCustomer = dto.roles.contains(PartnerRoleType.customer);
    final isSupplier = dto.roles.contains(PartnerRoleType.supplier);
    final labelRoles = switch ((isCustomer, isSupplier)) {
      (true, true) => 'KH & NCC',
      (true, false) => 'Khách hàng',
      (false, true) => 'Nhà cung cấp',
      (false, false) => 'Chưa có vai trò',
    };

    final initials = dto.displayName.trim().split(RegExp(r'\s+'));
    final avatarText = initials.isEmpty
        ? '?'
        : (initials.length == 1 ? initials[0][0] : '${initials[0][0]}${initials.last[0]}')
              .toUpperCase();
    final avatarBgColor = _avatarColor(dto.displayName);

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: avatarBgColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            avatarText,
            style: VTypography.headingH2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: VSpacing.space4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dto.displayName,
                style: VTypography.headingH3.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$labelType • $labelRoles',
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              if (dto.status == PartnerStatus.active)
                _StatusTag(text: 'Đang hoạt động', color: colors.success)
              else if (dto.status == PartnerStatus.inactive)
                _StatusTag(text: 'Ngừng hoạt động', color: colors.warning),
            ],
          ),
        ),
      ],
    );
  }

  static Color _avatarColor(String displayName) {
    const palette = [
      VColors.success,
      VColors.warning,
      VColors.info,
      VColors.primary,
      Color(0xFF9C27B0),
      Color(0xFF00BCD4),
    ];
    var sum = 0;
    for (var i = 0; i < displayName.length; i++) {
      sum += displayName.codeUnitAt(i);
    }
    return palette[sum % palette.length];
  }
}

/// Phone / MST quick row under the header.
class PartnerDetailContactQuickRow extends StatelessWidget {
  const PartnerDetailContactQuickRow({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      children: [
        VIcon(icon: VIcons.phone, size: 20, color: colors.textSecondary),
        const SizedBox(width: VSpacing.space3),
        Expanded(
          child: Text(
            text,
            style: VTypography.bodyDefault.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
}
