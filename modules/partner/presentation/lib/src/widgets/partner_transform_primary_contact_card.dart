import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';

class PartnerTransformPrimaryContactCard extends StatelessWidget {
  const PartnerTransformPrimaryContactCard({
    super.key,
    required this.person,
  });

  final PersonProfileDto person;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.success.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Text(
              'Cá nhân hiện tại sẽ được lưu làm người liên hệ chính',
              style: VTypography.bodyDefault.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(
              VSpacing.space3,
              0,
              VSpacing.space3,
              VSpacing.space3,
            ),
            padding: const EdgeInsets.all(VSpacing.space3),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(VRadius.card),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colors.success.withValues(alpha: 0.12),
                  child: Text(
                    _initials(person.fullName),
                    style: VTypography.headingH4.copyWith(
                      color: colors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(person.fullName, variant: VTextVariant.headingH4),
                      const SizedBox(height: VSpacing.space1),
                      VText(person.phone, variant: VTextVariant.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}
