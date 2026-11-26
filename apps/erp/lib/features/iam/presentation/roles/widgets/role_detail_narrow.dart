import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../logic/role_ui_model.dart';
import '../../shared/detail_layout.dart';
import 'role_card.dart';

class RoleDetailNarrow extends StatelessWidget {
  const RoleDetailNarrow({super.key, required this.role});

  final RoleUiModel role;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        DetailHeaderNarrow(
          leading: const DetailIconTile(VIcons.shield),
          title: role.title,
          subtitle: role.description,
          badge: Row(
            children: [
              VIcon(icon: VIcons.lock, size: 14, color: colors.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: VText(
                  'Vai trò hệ thống · Chỉ đọc',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: VText(
            'Thành viên đang giữ vai trò',
            variant: VTextVariant.headingH4,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        VCard(
          padding: EdgeInsets.zero,
          child: role.memberNames.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: VText(
                    'Chưa có thành viên đang giữ vai trò này.',
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < role.memberNames.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: colors.borderDefault),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 56),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              DetailAvatar(
                                holderInitial(role.memberNames[i]),
                                size: 36,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: VText(
                                  role.memberNames[i],
                                  variant: VTextVariant.bodyDefault,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
