import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../logic/role_ui_model.dart';
import 'role_card.dart';

class RolesNarrow extends StatelessWidget {
  const RolesNarrow({
    super.key,
    required this.loading,
    required this.failed,
    required this.roles,
    required this.onRetry,
    required this.onRoleTap,
  });

  final bool loading;
  final bool failed;
  final List<RoleUiModel> roles;
  final VoidCallback onRetry;
  final ValueChanged<RoleUiModel> onRoleTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    if (loading) {
      return const Center(child: VLoading(size: 40));
    }

    if (failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.screenMobile),
          child: RolesLoadError(onRetry: onRetry),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        Semantics(
          header: true,
          child: VText(
            'Vai trò hệ thống',
            variant: VTextVariant.headingH4,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const VGap.xs(),
        VText(
          'Vai trò vận hành không thay đổi tư cách Chủ sở hữu.',
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
        const VGap.md(),
        for (var i = 0; i < roles.length; i++) ...[
          if (i > 0) const SizedBox(height: VSpacing.space2),
          RoleCard(
            role: roles[i],
            onTap: () => onRoleTap(roles[i]),
          ),
        ],
      ],
    );
  }
}
