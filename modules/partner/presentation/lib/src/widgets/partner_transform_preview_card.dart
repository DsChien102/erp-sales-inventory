import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerTransformPreviewCard extends StatelessWidget {
  const PartnerTransformPreviewCard({
    super.key,
    required this.displayName,
    required this.subtitle,
    required this.phone,
    required this.avatarColor,
  });

  final String displayName;
  final String subtitle;
  final String phone;
  final Color avatarColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VCard(
      padding: const EdgeInsets.all(VSpacing.space3),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: avatarColor.withValues(alpha: 0.12),
            child: Text(
              _initials(displayName),
              style: VTypography.headingH4.copyWith(
                color: avatarColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: VTypography.bodyDefault.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: VSpacing.space1),
                Text(
                  subtitle,
                  style: VTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: VSpacing.space1),
                Text(
                  phone,
                  style: VTypography.bodyDefault.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) {
      final word = words.first;
      return word.substring(0, word.length.clamp(1, 2)).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}
