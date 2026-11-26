import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../logic/role_ui_model.dart';
import '../../shared/admin_table.dart';
import '../../shared/detail_layout.dart';
import 'role_card.dart';

class RolesWide extends StatelessWidget {
  const RolesWide({
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

    const columns = [
      AdminTableColumn('Vai trò hệ thống', flex: 1.4, minWidth: 280),
      AdminTableColumn('Thành viên đang giữ vai trò'),
    ];

    return AdminTablePage(
      children: [
        VText(
          'Vai trò vận hành không thay đổi tư cách Chủ sở hữu.',
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
        const SizedBox(height: 16),
        if (loading)
          const AdminTable(
            columns: columns,
            rows: [],
            loadingRows: 4,
            semanticLabel: 'Đang tải',
          )
        else if (failed)
          AdminTable(
            columns: columns,
            rows: const [],
            state: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: RolesLoadError(onRetry: onRetry),
              ),
            ),
          )
        else
          AdminTable(
            columns: columns,
            semanticLabel: 'Vai trò hệ thống',
            rows: roles.map((role) {
              final visibleHolders = role.memberNames.take(3).toList(growable: false);
              return AdminTableRow(
                semanticLabel: role.title,
                onTap: () => onRoleTap(role),
                cells: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VText(
                        role.title,
                        variant: VTextVariant.bodyDefault,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      VText(
                        role.description,
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                  if (role.memberNames.isEmpty)
                    VText(
                      'Chưa có thành viên đang giữ vai trò này.',
                      variant: VTextVariant.bodySmall,
                      color: colors.textMuted,
                    )
                  else
                    Row(
                      children: [
                        for (var i = 0; i < visibleHolders.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          DetailAvatar(holderInitial(visibleHolders[i]), size: 28),
                        ],
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            role.memberNames.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VTypography.bodyDefault.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              );
            }).toList(growable: false),
          ),
      ],
    );
  }
}
