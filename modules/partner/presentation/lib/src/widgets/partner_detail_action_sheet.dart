import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

enum PartnerDetailAction { transform, toggleStatus, delete }

class PartnerDetailActionSheet extends StatelessWidget {
  const PartnerDetailActionSheet({
    super.key,
    required this.dto,
    required this.onActionSelected,
  });

  final PartnerDetailDto dto;
  final ValueChanged<PartnerDetailAction> onActionSelected;

  Widget _buildStatusTag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: VTypography.bodySmall.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isPerson = dto.partnerType == PartnerType.person;
    final canTransform =
        isPerson && dto.availableActions.contains(PartnerAvailableAction.transform);
    final isInactive = dto.status == PartnerStatus.inactive;

    final typeLabel = isPerson ? 'Cá nhân' : 'Tổ chức';
    final roleLabel =
        dto.roles.contains(PartnerRoleType.customer) && dto.roles.contains(PartnerRoleType.supplier)
        ? 'KH & NCC'
        : (dto.roles.contains(PartnerRoleType.customer) ? 'Khách hàng' : 'Nhà cung cấp');
    final statusText = isInactive ? 'Ngừng hoạt động' : 'Đang hoạt động';
    final statusColor = isInactive ? colors.warning : colors.success;

    return VBottomSheet(
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VSpacing.space4,
                VSpacing.space4,
                VSpacing.space4,
                VSpacing.space2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thao tác hồ sơ',
                    style: VTypography.headingH3.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dto.displayName,
                    style: VTypography.bodyDefault.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        typeLabel,
                        style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                      ),
                      Text(
                        '  •  ',
                        style: VTypography.bodySmall.copyWith(color: colors.textMuted),
                      ),
                      Text(
                        roleLabel,
                        style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                      ),
                      Text(
                        '  •  ',
                        style: VTypography.bodySmall.copyWith(color: colors.textMuted),
                      ),
                      _buildStatusTag(context, statusText, statusColor),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: VSpacing.space2),
            Divider(color: colors.borderDefault, height: 1),
            if (canTransform)
              ListTile(
                leading: Icon(Icons.business_outlined, color: colors.textSecondary),
                title: Text(
                  'Chuyển thành tổ chức',
                  style: VTypography.bodyDefault.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Chuyển hồ sơ cá nhân thành tổ chức',
                  style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                onTap: () {
                  Navigator.of(context).pop();
                  onActionSelected(PartnerDetailAction.transform);
                },
              ),
            ListTile(
              leading: Icon(
                isInactive ? Icons.play_circle_outline_rounded : Icons.pause_circle_outline_rounded,
                color: colors.textSecondary,
              ),
              title: Text(
                isInactive ? 'Kích hoạt lại' : 'Ngừng hoạt động',
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                isInactive
                    ? 'Kích hoạt lại hồ sơ để thực hiện giao dịch'
                    : 'Tạm ngưng sử dụng trong hệ thống',
                style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: colors.textMuted),
              onTap: () {
                Navigator.of(context).pop();
                onActionSelected(PartnerDetailAction.toggleStatus);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: colors.danger),
              title: Text(
                'Xóa hồ sơ',
                style: VTypography.bodyDefault.copyWith(
                  color: colors.danger,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Xóa mềm, không hiển thị trong danh sách',
                style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: colors.textMuted),
              onTap: () {
                Navigator.of(context).pop();
                onActionSelected(PartnerDetailAction.delete);
              },
            ),
            const SizedBox(height: VSpacing.space2),
            // Cancel Button matching "Hủy" design in image 3
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space4,
                vertical: VSpacing.space3,
              ),
              child: VButton(
                label: 'Hủy',
                variant: VButtonVariant.outline,
                foregroundColor: colors.success,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: VSpacing.space4),
          ],
        ),
      ),
    );
  }
}
