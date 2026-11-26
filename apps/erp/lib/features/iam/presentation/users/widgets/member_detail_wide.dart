import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../shared/detail_layout.dart';
import '../bloc/organization_member_detail_state.dart';
import '../models/user_ui_model.dart';
import 'user_list_card.dart';

class MemberDetailWide extends StatelessWidget {
  const MemberDetailWide({
    super.key,
    required this.member,
    required this.onChangeRole,
    required this.onDeactivate,
    required this.onReactivate,
    required this.onRemove,
    required this.busy,
  });

  final MemberUiModel member;
  final VoidCallback? onChangeRole;
  final VoidCallback? onDeactivate;
  final VoidCallback? onReactivate;
  final VoidCallback? onRemove;
  final MembershipMutation? busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isActive = member.status == MemberStatus.active;
    final isSuspended = member.status == MemberStatus.suspended;
    final isRemoved = member.status == MemberStatus.removed;
    final (badgeLabel, badgeTone) = memberStatusBadge(member.status);

    final buttons = <Widget>[
      if (onChangeRole != null)
        VButton(
          label: 'Thay đổi vai trò',
          variant: VButtonVariant.secondary,
          fullWidth: true,
          isLoading: busy == MembershipMutation.changeRole,
          onPressed: busy != null ? null : onChangeRole,
        ),
      if (onDeactivate != null)
        VButton(
          label: 'Tạm ngừng thành viên',
          variant: VButtonVariant.secondary,
          fullWidth: true,
          isLoading: busy == MembershipMutation.deactivate,
          onPressed: busy != null ? null : onDeactivate,
        ),
      if (onReactivate != null)
        VButton(
          label: 'Kích hoạt lại',
          variant: VButtonVariant.secondary,
          fullWidth: true,
          isLoading: busy == MembershipMutation.reactivate,
          onPressed: busy != null ? null : onReactivate,
        ),
      if (onRemove != null)
        VButton(
          label: 'Loại khỏi tổ chức',
          variant: VButtonVariant.secondary,
          tone: VComponentTone.danger,
          fullWidth: true,
          isLoading: busy == MembershipMutation.remove,
          onPressed: busy != null ? null : onRemove,
        ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Opacity(
                opacity: isRemoved ? 0.6 : 1.0,
                child: DetailHeaderWide(
                  leading: DetailAvatar(
                    userInitial(member.name),
                    size: 48,
                    muted: !isActive,
                  ),
                  title: member.name,
                  subtitle: '${member.email} · ${member.role}',
                ),
              ),
              const SizedBox(height: 24),
              Opacity(
                opacity: isRemoved ? 0.6 : 1.0,
                child: DetailSectionWide(
                  title: 'Thông tin thành viên',
                  action: VBadge(
                    label: badgeLabel,
                    tone: badgeTone,
                    variant: VBadgeVariant.soft,
                    isSmall: true,
                  ),
                  children: [
                    DetailRow(
                      label: 'Tên',
                      value: member.name.isNotEmpty ? member.name : '—',
                    ),
                    DetailRow(
                      label: 'Email',
                      value: member.email.isNotEmpty ? member.email : '—',
                    ),
                    DetailRow(label: 'Vai trò hiện hành', value: member.role),
                    DetailRow(
                      label: 'Quyền sở hữu',
                      value: member.identityText,
                    ),
                  ],
                ),
              ),
              if (isSuspended) ...[
                const SizedBox(height: 16),
                const VBanner(
                  title: 'Quyền truy cập đã tạm ngừng',
                  description:
                      'Thành viên không thể truy cập tổ chức cho đến khi được kích hoạt lại.',
                  status: VBannerStatus.warning,
                ),
              ] else if (isRemoved) ...[
                const SizedBox(height: 16),
                const VBanner(
                  title: 'Thành viên đã được loại',
                  description:
                      'Quyền truy cập đã kết thúc. Lịch sử và dữ liệu nghiệp vụ vẫn được giữ lại.',
                  status: VBannerStatus.info,
                ),
              ],
              const SizedBox(height: 16),
              DetailSectionWide(
                title: 'Trạng thái truy cập',
                children: [
                  if (isActive) ...[
                    DetailRow(
                      label: 'Ngày tham gia',
                      value: member.joinedDate,
                    ),
                    DetailRow(
                      label: 'Hoạt động gần nhất',
                      value: member.lastActiveDate.isNotEmpty
                          ? member.lastActiveDate
                          : '—',
                    ),
                  ] else if (isSuspended) ...[
                    DetailRow(
                      label: 'Tạm ngừng lúc',
                      value: member.suspendedAt ?? '—',
                    ),
                  ] else ...[
                    DetailRow(
                      label: 'Đã loại lúc',
                      value: member.removedAt ?? '—',
                    ),
                    DetailRow(label: 'Vai trò trước đó', value: member.role),
                  ],
                  if (buttons.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: colors.borderDefault),
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cols = constraints.maxWidth >= 600
                              ? 3
                              : (constraints.maxWidth >= 420 ? 2 : 1);
                          final itemWidth =
                              (constraints.maxWidth - 12 * (cols - 1)) / cols;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final btn in buttons)
                                SizedBox(width: itemWidth, child: btn),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
