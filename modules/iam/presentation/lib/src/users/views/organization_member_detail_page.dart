import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/user_ui_model.dart';

/// Trang Chi tiết thành viên (TA-D-01).
class OrganizationMemberDetailPage extends StatefulWidget {
  final MemberUiModel member;

  const OrganizationMemberDetailPage({
    super.key,
    required this.member,
  });

  @override
  State<OrganizationMemberDetailPage> createState() => _OrganizationMemberDetailPageState();
}

class _OrganizationMemberDetailPageState extends State<OrganizationMemberDetailPage> {
  late MemberUiModel _member;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
  }

  void _showActionBottomSheet(BuildContext context) {
    final isActive = _member.status == MemberStatus.active;

    showVBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.only(
          left: VSpacing.space4,
          right: VSpacing.space4,
          top: VSpacing.space2,
          bottom: VSpacing.space6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VText(
              'Thao tác thành viên',
              variant: VTextVariant.headingH3,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const VGap.md(),
            _buildBottomSheetOption(
              icon: VIcons.shield,
              title: 'Thay đổi vai trò',
              subtitle: isActive ? 'Cập nhật quyền vận hành' : 'Cập nhật quyền khi kích hoạt lại',
              onTap: () async {
                Navigator.of(context).pop();
                final newRole = await context.push<String>(
                  '/more/users/select-role',
                  extra: _member,
                );
                if (newRole != null && context.mounted) {
                  _showChangeRoleConfirmBottomSheet(context, newRole);
                }
              },
            ),
            const VGap.sm(),
            _buildBottomSheetOption(
              icon: isActive ? VIcons.pause : VIcons.personCheck,
              title: isActive ? 'Tạm ngừng thành viên' : 'Kích hoạt lại',
              subtitle: isActive ? 'Dừng quyền truy cập tạm thời' : 'Khôi phục quyền truy cập',
              onTap: () {
                Navigator.of(context).pop();
                if (isActive) {
                  _showSuspendConfirmBottomSheet(context);
                } else {
                  _showReactivateConfirmBottomSheet(context);
                }
              },
            ),
            const VGap.sm(),
            _buildBottomSheetOption(
              icon: VIcons.personRemove,
              title: 'Loại khỏi tổ chức',
              subtitle: 'Kết thúc tư cách thành viên',
              isDanger: true,
              onTap: () {
                Navigator.of(context).pop();
                _showRemoveConfirmBottomSheet(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeRoleConfirmBottomSheet(BuildContext context, String newRole) {
    final colors = context.vColors;

    showVBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.only(
          left: VSpacing.space4,
          right: VSpacing.space4,
          top: VSpacing.space2,
          bottom: VSpacing.space6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VText(
              'Đổi vai trò của ${_member.name}?',
              variant: VTextVariant.headingH3,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const VGap.xs(),
            VText(
              'Vai trò ${_member.role} → $newRole. Quyền mới có hiệu lực ở yêu cầu tiếp theo.',
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const VGap.xl(),
            VButton(
              label: 'Quay lại',
              variant: VButtonVariant.outline,
              tone: VComponentTone.neutral,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const VGap.sm(),
            VButton(
              label: 'Xác nhận thay đổi',
              variant: VButtonVariant.primary,
              tone: VComponentTone.success,
              fullWidth: true,
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _member = MemberUiModel(
                    id: _member.id,
                    name: _member.name,
                    email: _member.email,
                    role: newRole,
                    status: _member.status,
                    identityText: _member.identityText,
                    joinedDate: _member.joinedDate,
                    lastActiveDate: _member.lastActiveDate,
                    dataVersion: 'v9',
                    suspendedAt: _member.suspendedAt,
                    suspendedBy: _member.suspendedBy,
                  );
                });
                VToast.show(
                  context,
                  title: 'Đã thay đổi vai trò.',
                  message: '',
                  type: VToastType.success,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSuspendConfirmBottomSheet(BuildContext context) {
    final colors = context.vColors;

    showVBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.only(
          left: VSpacing.space4,
          right: VSpacing.space4,
          top: VSpacing.space2,
          bottom: VSpacing.space6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VText(
              'Tạm ngừng thành viên?',
              variant: VTextVariant.headingH3,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.danger,
              ),
            ),
            const VGap.xs(),
            VText(
              'Thành viên mất quyền truy cập tới khi được kích hoạt lại.',
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const VGap.xl(),
            VButton(
              label: 'Quay lại',
              variant: VButtonVariant.outline,
              tone: VComponentTone.neutral,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const VGap.sm(),
            VButton(
              label: 'Tạm ngừng',
              variant: VButtonVariant.dangerOutline,
              fullWidth: true,
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _member = MemberUiModel(
                    id: _member.id,
                    name: _member.name,
                    email: _member.email,
                    role: _member.role,
                    status: MemberStatus.suspended,
                    identityText: _member.identityText,
                    joinedDate: _member.joinedDate,
                    lastActiveDate: _member.lastActiveDate,
                    dataVersion: _member.dataVersion,
                    suspendedAt: _member.suspendedAt ?? '14/07/2026 · 09:30',
                    suspendedBy: _member.suspendedBy ?? 'Lê Thị Lan',
                  );
                });
                VToast.show(
                  context,
                  title: 'Đã tạm ngừng thành viên.',
                  message: '',
                  type: VToastType.success,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReactivateConfirmBottomSheet(BuildContext context) {
    final colors = context.vColors;

    showVBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.only(
          left: VSpacing.space4,
          right: VSpacing.space4,
          top: VSpacing.space2,
          bottom: VSpacing.space6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VText(
              'Kích hoạt lại thành viên?',
              variant: VTextVariant.headingH3,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const VGap.xs(),
            VText(
              'Quyền truy cập sẽ được khôi phục theo vai trò hiện hành.',
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const VGap.xl(),
            VButton(
              label: 'Quay lại',
              variant: VButtonVariant.outline,
              tone: VComponentTone.neutral,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const VGap.sm(),
            VButton(
              label: 'Kích hoạt lại',
              variant: VButtonVariant.primary,
              tone: VComponentTone.success,
              fullWidth: true,
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _member = MemberUiModel(
                    id: _member.id,
                    name: _member.name,
                    email: _member.email,
                    role: _member.role,
                    status: MemberStatus.active,
                    identityText: _member.identityText,
                    joinedDate: _member.joinedDate,
                    lastActiveDate: _member.lastActiveDate,
                    dataVersion: 'v10',
                    suspendedAt: _member.suspendedAt,
                    suspendedBy: _member.suspendedBy,
                  );
                });
                VToast.show(
                  context,
                  title: 'Đã kích hoạt lại thành viên.',
                  message: '',
                  type: VToastType.success,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveConfirmBottomSheet(BuildContext context) {
    final colors = context.vColors;

    showVBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.only(
          left: VSpacing.space4,
          right: VSpacing.space4,
          top: VSpacing.space2,
          bottom: VSpacing.space6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VText(
              'Loại thành viên khỏi tổ chức?',
              variant: VTextVariant.headingH3,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.danger,
              ),
            ),
            const VGap.xs(),
            VText(
              'Membership sẽ kết thúc vĩnh viễn. Người này cần lời mời mới nếu quay lại.',
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const VGap.xl(),
            VButton(
              label: 'Quay lại',
              variant: VButtonVariant.outline,
              tone: VComponentTone.neutral,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const VGap.sm(),
            VButton(
              label: 'Loại thành viên',
              variant: VButtonVariant.dangerOutline,
              fullWidth: true,
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _member = MemberUiModel(
                    id: _member.id,
                    name: _member.name,
                    email: _member.email,
                    role: _member.role,
                    status: MemberStatus.removed,
                    identityText: _member.identityText,
                    joinedDate: _member.joinedDate,
                    lastActiveDate: _member.lastActiveDate,
                    dataVersion: _member.dataVersion,
                    suspendedAt: _member.suspendedAt,
                    suspendedBy: _member.suspendedBy,
                    removedAt: _member.removedAt ?? '14/07/2026 · 09:45',
                    removedBy: _member.removedBy ?? 'Lê Thị Lan',
                    previousRole: _member.previousRole ?? _member.role,
                  );
                });
                VToast.show(
                  context,
                  title: 'Đã loại thành viên khỏi tổ chức.',
                  message: '',
                  type: VToastType.success,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required VIcons icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final colors = context.vColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VRadius.card),
      child: Container(
        padding: const EdgeInsets.all(VSpacing.space4),
        decoration: BoxDecoration(
          color: isDanger ? colors.dangerBg : colors.surface,
          border: Border.all(
            color: isDanger ? colors.danger : colors.borderDefault,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(VRadius.card),
        ),
        child: Row(
          children: [
            VIcon(
              icon: icon,
              size: 24,
              color: isDanger ? colors.danger : colors.textPrimary,
            ),
            const VGap.horizontalMd(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    title,
                    variant: VTextVariant.bodyDefault,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDanger ? colors.danger : colors.textPrimary,
                    ),
                  ),
                  const VGap.xs(),
                  VText(
                    subtitle,
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
            VIcon(
              icon: VIcons.chevronRight,
              size: 20,
              color: isDanger ? colors.danger : colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final member = _member;
    final isActive = member.status == MemberStatus.active;
    final isSuspended = member.status == MemberStatus.suspended;
    final isRemoved = member.status == MemberStatus.removed;

    return VPageScaffold(
      title: 'Chi tiết thành viên',
      bottomBar: isRemoved
          ? null
          : Padding(
              padding: const EdgeInsets.all(VSpacing.screenMobile),
              child: VButton(
                label: 'Thao tác',
                trailingIcon: const VIcon(
                  icon: VIcons.chevronUp,
                  size: 18,
                  color: Colors.white,
                ),
                variant: VButtonVariant.primary,
                tone: VComponentTone.success,
                fullWidth: true,
                onPressed: () => _showActionBottomSheet(context),
              ),
            ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ListView(
          padding: const EdgeInsets.all(VSpacing.screenMobile),
          children: [
            // Card 1: Top summary card (Disabled look when isRemoved is true)
            Opacity(
              opacity: isRemoved ? 0.6 : 1.0,
              child: VCard(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: VText(
                            member.name,
                            variant: VTextVariant.headingH4,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        VBadge(
                          label: isActive
                              ? 'Hoạt động'
                              : isSuspended
                              ? 'Tạm ngừng'
                              : 'Đã loại',
                          status: isActive ? VBadgeStatus.success : VBadgeStatus.danger,
                          isSmall: true,
                        ),
                      ],
                    ),
                    const VGap.xs(),
                    VText(
                      '${member.email} · ${member.role}',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                    const VGap.md(),
                    VText(
                      'Danh tính ${member.identityText}',
                      variant: VTextVariant.bodyDefault,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
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

            // Card 2: Thông tin thành viên
            VCard(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    'Thông tin thành viên',
                    variant: VTextVariant.headingH4,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const VGap.md(),
                  _buildDetailRow('Email', member.email),
                  const VGap.md(),
                  _buildDetailRow('Vai trò hiện hành', member.role),
                  const VGap.md(),
                  _buildDetailRow('Danh tính', member.identityText),
                ],
              ),
            ),
            const VGap.md(),

            // Card 3: Trạng thái truy cập
            VCard(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    'Trạng thái truy cập',
                    variant: VTextVariant.headingH4,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const VGap.md(),
                  if (isActive) ...[
                    _buildDetailRow('Ngày tham gia', member.joinedDate),
                    const VGap.md(),
                    _buildDetailRow('Hoạt động gần nhất', member.lastActiveDate),
                    const VGap.md(),
                    _buildDetailRow('Phiên bản dữ liệu', member.dataVersion),
                  ] else if (isSuspended) ...[
                    _buildDetailRow('Tạm ngừng lúc', member.suspendedAt ?? '14/07/2026 · 09:30'),
                    const VGap.md(),
                    _buildDetailRow('Người thực hiện', member.suspendedBy ?? 'Lê Thị Lan'),
                  ] else ...[
                    _buildDetailRow('Đã loại lúc', member.removedAt ?? '14/07/2026 · 09:45'),
                    const VGap.md(),
                    _buildDetailRow('Người thực hiện', member.removedBy ?? 'Lê Thị Lan'),
                    const VGap.md(),
                    _buildDetailRow('Vai trò trước đó', member.previousRole ?? member.role),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final colors = context.vColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(
          label,
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
        VText(
          value,
          variant: VTextVariant.bodySmall,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
