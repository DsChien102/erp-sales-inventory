import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../logic/role_ui_model.dart';

class RoleDetailWide extends StatelessWidget {
  const RoleDetailWide({super.key, required this.role});

  final RoleUiModel role;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VCard(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: VText(
                        role.title,
                        variant: VTextVariant.headingH4,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const VGap.xs(),
                    VText(
                      role.description,
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                    const VGap.md(),
                    VText(
                      'Vai trò hệ thống · Chỉ đọc',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
              const VGap.md(),
              Semantics(
                header: true,
                child: VText(
                  'Thành viên đang giữ vai trò',
                  variant: VTextVariant.headingH4,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const VGap.sm(),
              if (role.memberNames.isEmpty)
                VText(
                  'Chưa có thành viên đang giữ vai trò này.',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                )
              else
                ...role.memberNames.map(
                  (name) => Padding(
                    padding: const EdgeInsets.only(bottom: VSpacing.space2),
                    child: VText(name, variant: VTextVariant.bodyDefault),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
