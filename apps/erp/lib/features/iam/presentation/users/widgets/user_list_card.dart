import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../models/user_ui_model.dart';

String userInitial(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  final last = parts.last;
  if (last.isEmpty) return '?';
  return last.characters.first.toUpperCase();
}

String invitationInitial(String email) {
  final trimmed = email.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.first.toUpperCase();
}

(String, VComponentTone) memberStatusBadge(MemberStatus status) {
  return switch (status) {
    MemberStatus.active => ('Hoạt động', VComponentTone.success),
    MemberStatus.suspended => ('Tạm ngừng', VComponentTone.danger),
    MemberStatus.removed => ('Đã loại', VComponentTone.danger),
  };
}

(String, VComponentTone) invitationStatusBadge(InvitationStatus status) {
  return switch (status) {
    // Như INVITATION_BADGE (prototype) và InvitationCard cũ.
    InvitationStatus.pending => ('Đang chờ', VComponentTone.warning),
    InvitationStatus.expiring => ('Sắp hết hạn', VComponentTone.danger),
    InvitationStatus.failed => ('Lỗi gửi', VComponentTone.danger),
    InvitationStatus.accepted => ('Đã chấp nhận', VComponentTone.success),
    InvitationStatus.declined => ('Đã từ chối', VComponentTone.neutral),
    InvitationStatus.revoked => ('Đã thu hồi', VComponentTone.neutral),
    InvitationStatus.expired => ('Hết hạn', VComponentTone.neutral),
  };
}

class UserListCard extends StatelessWidget {
  const UserListCard({
    super.key,
    required this.title,
    required this.badges,
    required this.lines,
    this.onTap,
    this.isSelected = false,
  });

  factory UserListCard.member({
    Key? key,
    required MemberUiModel member,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    final (label, tone) = memberStatusBadge(member.status);
    return UserListCard(
      key: key,
      title: member.name,
      badges: [
        if (member.isOwner)
          const VBadge(
            label: 'Chủ sở hữu',
            tone: VComponentTone.primary,
            variant: VBadgeVariant.soft,
            isSmall: true,
          ),
        VBadge(
          label: label,
          tone: tone,
          variant: VBadgeVariant.soft,
          isSmall: true,
        ),
      ],
      lines: [
        UserCardLine(icon: VIcons.mail, text: member.email),
        UserCardLine(icon: VIcons.shield, text: member.role),
      ],
      onTap: onTap,
      isSelected: isSelected,
    );
  }

  factory UserListCard.invitation({
    Key? key,
    required InvitationUiModel invitation,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    final (label, tone) = invitationStatusBadge(invitation.status);
    final detailLine = invitation.expiryLabel.isEmpty
        ? invitation.deliveryLabel
        : '${invitation.expiryLabel} · ${invitation.deliveryLabel}';
    return UserListCard(
      key: key,
      title: invitation.email,
      badges: [
        VBadge(
          label: label,
          tone: tone,
          variant: VBadgeVariant.soft,
          isSmall: true,
        ),
      ],
      lines: [
        UserCardLine(icon: VIcons.shield, text: invitation.role),
        UserCardLine(icon: VIcons.clock, text: detailLine),
      ],
      onTap: onTap,
      isSelected: isSelected,
    );
  }

  final String title;
  final List<Widget> badges;
  final List<UserCardLine> lines;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space3,
      ),
      border: isSelected ? null : Border.all(color: colors.borderStrong),
      backgroundColor: isSelected ? null : colors.surface,
      isSelected: isSelected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Như `.t1-ucard__name`: tên + nhãn phụ (Chủ sở hữu) liền sau tên;
          // nhãn cuối (trạng thái) dạt phải.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: VSpacing.space2,
                  runSpacing: VSpacing.space1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    VText(
                      title,
                      variant: VTextVariant.bodyDefault,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (badges.length > 1)
                      ...badges.sublist(0, badges.length - 1),
                  ],
                ),
              ),
              if (badges.isNotEmpty) ...[
                const SizedBox(width: VSpacing.space2),
                badges.last,
              ],
            ],
          ),
          for (final line in lines) ...[
            const SizedBox(height: VSpacing.space1),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: VIcon(
                    icon: line.icon,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                Expanded(
                  child: VText(
                    line.text,
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class UserCardLine {
  const UserCardLine({required this.icon, required this.text});

  final VIcons icon;
  final String text;
}
