import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../logic/role_ui_model.dart';
import '../../shared/detail_layout.dart';

String holderInitial(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.last.isEmpty) return '?';
  return parts.last.characters.first.toUpperCase();
}

/// Thẻ vai trò trên màn hình hẹp (prototype `.t1-rolecard`).
class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.role,
    required this.onTap,
  });

  final RoleUiModel role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final visibleHolders = role.memberNames.take(3).toList(growable: false);

    return VCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            VText(
                              role.title,
                              variant: VTextVariant.bodyDefault,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            if (role.isCurrent)
                              const VBadge(
                                label: 'Đang dùng',
                                tone: VComponentTone.success,
                                variant: VBadgeVariant.soft,
                                isSmall: true,
                              ),
                          ],
                        ),
                        VText(
                          role.description,
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  VIcon(
                    icon: VIcons.chevronRight,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: colors.borderDefault),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: role.memberNames.isEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: VText(
                        'Chưa có thành viên đang giữ vai trò này.',
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    )
                  : Row(
                      children: [
                        for (var i = 0; i < visibleHolders.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          DetailAvatar(holderInitial(visibleHolders[i]), size: 28),
                        ],
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            role.memberNames.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VTypography.bodySmall.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Khối lỗi tải vai trò dùng chung cho danh sách và chi tiết (Q5).
class RolesLoadError extends StatelessWidget {
  const RolesLoadError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VCard(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space5,
        vertical: VSpacing.space6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.dangerBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: VIcon(
                icon: VIcons.close,
                size: 28,
                color: colors.danger,
              ),
            ),
          ),
          const VGap.md(),
          Semantics(
            header: true,
            child: VText(
              'Không thể tải danh sách vai trò',
              variant: VTextVariant.headingH3,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.danger,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const VGap.xs(),
          VText(
            'Dịch vụ phân quyền đang tạm thời không khả dụng. Vui lòng thử lại sau.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
            textAlign: TextAlign.center,
          ),
          const VGap.md(),
          VButton(
            label: 'Thử lại',
            variant: VButtonVariant.link,
            tone: VComponentTone.danger,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
