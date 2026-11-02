import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';

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
            child: VText(
              'Cá nhân hiện tại sẽ được lưu làm người liên hệ chính',
              variant: VTextVariant.bodyDefault,
              color: colors.textPrimary,
              style: const TextStyle(fontWeight: FontWeight.w700),
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
                VAvatar(name: person.fullName, size: 56, textSize: 18),
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
}
