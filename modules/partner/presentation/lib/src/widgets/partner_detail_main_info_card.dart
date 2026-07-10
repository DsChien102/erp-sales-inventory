import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';

import 'partner_detail_expandable_card.dart';
import 'partner_detail_formatters.dart';

/// Card «Thông tin chính» — SĐT chính và email; tap header để mở/đóng.
class PartnerDetailMainInfoCard extends StatelessWidget {
  const PartnerDetailMainInfoCard({
    super.key,
    required this.dto,
    this.initiallyExpanded = false,
  });

  final PartnerDetailDto dto;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final phone = PartnerDetailFormatters.primaryPhone(dto)?.trim() ?? '';
    final email = PartnerDetailFormatters.primaryEmail(dto)?.trim() ?? '';

    return PartnerDetailExpandableCard(
      title: 'Thông tin chính',
      icon: Icons.assignment_ind_outlined,
      initiallyExpanded: initiallyExpanded,
      trailingWhenCollapsed: phone.isEmpty
          ? null
          : Text(
              phone,
              style: VTypography.bodySmall.copyWith(
                color: colors.textSecondary,
                fontSize: 11,
              ),
            ),
      child: phone.isEmpty && email.isEmpty
          ? Text(
              'Chưa có SĐT / email',
              style: VTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (phone.isNotEmpty)
                  _ContactLine(
                    icon: Icons.phone_outlined,
                    label: 'SĐT chính',
                    value: phone,
                  ),
                if (phone.isNotEmpty && email.isNotEmpty)
                  const SizedBox(height: VSpacing.space2),
                if (email.isNotEmpty)
                  _ContactLine(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    value: email,
                  ),
              ],
            ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colors.textSecondary),
        const SizedBox(width: VSpacing.space2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: VTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
