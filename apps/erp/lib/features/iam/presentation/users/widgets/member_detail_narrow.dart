import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../shared/detail_layout.dart';
import '../models/user_ui_model.dart';
import 'user_list_card.dart';

class MemberDetailNarrow extends StatelessWidget {
  const MemberDetailNarrow({
    super.key,
    required this.member,
  });

  final MemberUiModel member;

  @override
  Widget build(BuildContext context) {
    final isActive = member.status == MemberStatus.active;
    final isSuspended = member.status == MemberStatus.suspended;
    final isRemoved = member.status == MemberStatus.removed;
    final (badgeLabel, badgeTone) = memberStatusBadge(member.status);

    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        Opacity(
          opacity: isRemoved ? 0.6 : 1.0,
          child: DetailHeaderNarrow(
            leading: DetailAvatar(
              userInitial(member.name),
              size: 52,
              muted: !isActive,
            ),
            title: member.name,
            subtitle: member.email,
          ),
        ),
        const VGap.md(),
        Opacity(
          opacity: isRemoved ? 0.6 : 1.0,
          child: DetailSectionNarrow(
            title: 'Thông tin thành viên',
            trailing: VBadge(
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
              DetailRow(label: 'Quyền sở hữu', value: member.identityText),
            ],
          ),
        ),
        if (isSuspended) ...[
          const VGap.md(),
          const VBanner(
            title: 'Quyền truy cập đã tạm ngừng',
            description:
                'Thành viên không thể truy cập tổ chức cho đến khi được kích hoạt lại.',
            status: VBannerStatus.warning,
          ),
        ] else if (isRemoved) ...[
          const VGap.md(),
          const VBanner(
            title: 'Thành viên đã được loại',
            description:
                'Quyền truy cập đã kết thúc. Lịch sử và dữ liệu nghiệp vụ vẫn được giữ lại.',
            status: VBannerStatus.info,
          ),
        ],
        const VGap.md(),
        DetailSectionNarrow(
          title: 'Trạng thái truy cập',
          children: [
            if (isActive) ...[
              DetailRow(label: 'Ngày tham gia', value: member.joinedDate),
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
          ],
        ),
      ],
    );
  }
}
