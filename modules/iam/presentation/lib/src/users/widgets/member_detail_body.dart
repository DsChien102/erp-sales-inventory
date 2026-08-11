import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_domain/domain.dart';

import '../models/user_ui_model.dart';

/// Read-only body for member detail (summary + info + access status).
class MemberDetailBody extends StatelessWidget {
  const MemberDetailBody({
    super.key,
    required this.member,
    required this.detailStatus,
  });

  final MemberUiModel member;
  final MembershipStatus detailStatus;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isActive = detailStatus == MembershipStatus.active;
    final isInactive = detailStatus == MembershipStatus.inactive;
    final isRemoved = detailStatus == MembershipStatus.removed;

    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
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
                          : isInactive
                              ? 'Tạm ngừng'
                              : 'Đã loại',
                      status: isActive
                          ? VBadgeStatus.success
                          : VBadgeStatus.danger,
                      isSmall: true,
                    ),
                  ],
                ),
                const VGap.xs(),
                VText(
                  member.email.isEmpty
                      ? member.role
                      : '${member.email} · ${member.role}',
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
        if (isInactive) ...[
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
              _DetailRow(label: 'User ID', value: member.name),
              const VGap.md(),
              _DetailRow(label: 'Vai trò hiện hành', value: member.role),
              const VGap.md(),
              _DetailRow(label: 'Danh tính', value: member.identityText),
            ],
          ),
        ),
        const VGap.md(),
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
                _DetailRow(label: 'Ngày tham gia', value: member.joinedDate),
                const VGap.md(),
                _DetailRow(
                  label: 'Phiên bản dữ liệu',
                  value: member.dataVersion,
                ),
              ] else if (isInactive) ...[
                _DetailRow(
                  label: 'Tạm ngừng lúc',
                  value: member.suspendedAt ?? '—',
                ),
              ] else ...[
                _DetailRow(
                  label: 'Đã loại lúc',
                  value: member.removedAt ?? '—',
                ),
                const VGap.md(),
                _DetailRow(
                  label: 'Vai trò trước đó',
                  value: member.previousRole ?? member.role,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(
          label,
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
        Flexible(
          child: VText(
            value,
            variant: VTextVariant.bodySmall,
            style: const TextStyle(fontWeight: FontWeight.w700),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
