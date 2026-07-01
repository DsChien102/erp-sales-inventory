import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerListItem extends StatelessWidget {
  final String avatarText;
  final String name;
  final String role;
  final Color roleColor;
  final Color roleBgColor;
  final String status;
  final String info;

  const PartnerListItem({
    super.key,
    required this.avatarText,
    required this.name,
    required this.role,
    required this.roleColor,
    required this.roleBgColor,
    required this.status,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return VCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: VColors.successBg,
            child: Text(
              avatarText,
              style: VTypography.bodyDefault.copyWith(
                color: VColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: VTypography.bodyDefault.copyWith(
                    fontWeight: FontWeight.w600,
                    color: dynamicColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        role,
                        style: VTypography.bodySmall.copyWith(
                          color: roleColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: VColors.successBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: VTypography.bodySmall.copyWith(
                          color: VColors.success,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  info,
                  style: VTypography.bodySmall.copyWith(
                    color: dynamicColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: dynamicColors.textMuted),
        ],
      ),
    );
  }
}
