import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

class PlatformUserMembershipList extends StatelessWidget {
  const PlatformUserMembershipList({super.key, required this.memberships});

  final List<PlatformUserMembershipDto> memberships;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            'Tổ chức đang tham gia',
            variant: VTextVariant.bodyDefault,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const VGap.md(),
          if (memberships.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: VSpacing.space2),
              child: VText(
                'Chưa tham gia tổ chức nào.',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            )
          else
            ...memberships.map((membership) {
              final isLast = memberships.last == membership;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : VSpacing.space2),
                child: VCard(
                  onTap: () {
                    context.pushNamed(
                      'organization_detail',
                      pathParameters: {'tenantId': membership.tenantId},
                    );
                  },
                  child: Row(
                    children: [
                      VIcon(
                        icon: VIcons.apartment,
                        color: colors.textSecondary,
                        size: 24,
                      ),
                      const VGap.horizontalMd(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            VText(
                              membership.tenantName,
                              variant: VTextVariant.bodyDefault,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const VGap.xs(),
                            VText(
                              'Tổ chức đang tham gia',
                              variant: VTextVariant.bodySmall,
                              color: colors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      VIcon(
                        icon: VIcons.chevronRight,
                        color: colors.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
