import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/user_ui_model.dart';
import '../widgets/member_detail_bottom_sheets.dart';

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
            MemberDetailOptionItem(
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
                  showChangeRoleConfirmBottomSheet(
                    context: context,
                    member: _member,
                    newRole: newRole,
                    onConfirmed: (updated) => setState(() => _member = updated),
                  );
                }
              },
            ),
            const VGap.sm(),
            MemberDetailOptionItem(
              icon: isActive ? VIcons.pause : VIcons.personCheck,
              title: isActive ? 'Tạm ngừng thành viên' : 'Kích hoạt lại',
              subtitle: isActive ? 'Dừng quyền truy cập tạm thời' : 'Khôi phục quyền truy cập',
              onTap: () {
                Navigator.of(context).pop();
                if (isActive) {
                  showSuspendConfirmBottomSheet(
                    context: context,
                    member: _member,
                    onConfirmed: (updated) => setState(() => _member = updated),
                  );
                } else {
                  showReactivateConfirmBottomSheet(
                    context: context,
                    member: _member,
                    onConfirmed: (updated) => setState(() => _member = updated),
                  );
                }
              },
            ),
            const VGap.sm(),
            MemberDetailOptionItem(
              icon: VIcons.personRemove,
              title: 'Loại khỏi tổ chức',
              subtitle: 'Kết thúc tư cách thành viên',
              isDanger: true,
              onTap: () {
                Navigator.of(context).pop();
                showRemoveConfirmBottomSheet(
                  context: context,
                  member: _member,
                  onConfirmed: (updated) => setState(() => _member = updated),
                );
              },
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
                  color: VColors.neutral0,
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
