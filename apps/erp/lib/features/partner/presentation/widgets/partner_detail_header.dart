import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';

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

    return Row(
      children: [
        VAvatar(name: dto.displayName, size: 64, textSize: 24),
        const SizedBox(width: VSpacing.space4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VText(
                dto.displayName,
                variant: VTextVariant.headingH3,
                color: colors.textPrimary,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: VSpacing.space1),
              VText(
                '$labelType • $labelRoles',
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
              ),
              const VGap.sm(),
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
          child: VText(
            text,
            variant: VTextVariant.bodyDefault,
            color: colors.textPrimary,
            style: const TextStyle(fontWeight: FontWeight.w500),
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
}
