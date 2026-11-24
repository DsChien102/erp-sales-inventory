import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class PartnerTransformPreviewCard extends StatelessWidget {
  const PartnerTransformPreviewCard({
    super.key,
    required this.displayName,
    required this.subtitle,
    required this.phone,
  });

  final String displayName;
  final String subtitle;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VCard(
      padding: const EdgeInsets.all(VSpacing.space3),
      child: Row(
        children: [
          VAvatar(name: displayName, size: 54, textSize: 18),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  displayName,
                  variant: VTextVariant.bodyDefault,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: VSpacing.space1),
                VText(
                  subtitle,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
                const SizedBox(height: VSpacing.space1),
                VText(
                  phone,
                  variant: VTextVariant.bodyDefault,
                  color: colors.textSecondary,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
