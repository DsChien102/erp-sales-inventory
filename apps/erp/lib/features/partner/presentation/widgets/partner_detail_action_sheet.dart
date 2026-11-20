import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';

enum PartnerDetailAction { transform, toggleStatus, delete }

Future<PartnerDetailAction?> showPartnerDetailActionSheet(
  BuildContext context, {
  required PartnerDetailDto dto,
}) {
  return showVAdaptiveSheet<PartnerDetailAction>(
    context: context,
    child: PartnerDetailActionSheet(dto: dto),
  );
}

/// Action sheet «Thao tác hồ sơ» — entry cho transform (S6), status (S7), soft delete (S8).
///
/// Pop sheet với [PartnerDetailAction]; caller xử lý sau khi sheet đóng.
class PartnerDetailActionSheet extends StatelessWidget {
  const PartnerDetailActionSheet({
    super.key,
    required this.dto,
  });

  final PartnerDetailDto dto;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isPerson = dto.partnerType == PartnerType.person;
    final isInactive = dto.status == PartnerStatus.inactive;
    final actions = dto.availableActions.toSet();

    final canTransform = isPerson && actions.contains(PartnerAvailableAction.transform);
    final canToggleStatus = isInactive
        ? actions.contains(PartnerAvailableAction.reactivate)
        : actions.contains(PartnerAvailableAction.deactivate);
    final canDelete = actions.contains(PartnerAvailableAction.delete);

    void select(PartnerDetailAction action) {
      Navigator.of(context).pop(action);
    }

    return Material(
      key: const Key('wgt_e02_u01_fr01_01'),
      color: colors.surface.withValues(alpha: 0),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
                child: VText(
                  'Thao tác hồ sơ',
                  variant: VTextVariant.headingH3,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (canTransform)
                _ActionCard(
                  key: const Key('action_transform'),
                  icon: VIcons.apartment,
                  iconBackground: colors.successBg,
                  iconColor: colors.success,
                  title: 'Chuyển thành tổ chức',
                  subtitle: 'Chuyển hồ sơ cá nhân hiện tại sang hồ sơ tổ chức.',
                  onTap: () => select(PartnerDetailAction.transform),
                ),
              if (canToggleStatus)
                _ActionCard(
                  key: const Key('action_toggle_status'),
                  icon: isInactive ? VIcons.power : VIcons.pause,
                  iconBackground: isInactive ? colors.successBg : colors.warningBg,
                  iconColor: isInactive ? colors.success : colors.warning,
                  title: isInactive ? 'Kích hoạt lại' : 'Ngừng hoạt động',
                  subtitle: isInactive
                      ? 'Cho phép sử dụng lại trong hệ thống.'
                      : 'Tạm ngừng sử dụng trong hệ thống.',
                  onTap: () => select(PartnerDetailAction.toggleStatus),
                ),
              if (canDelete)
                _ActionCard(
                  key: const Key('action_delete'),
                  icon: VIcons.delete,
                  iconBackground: colors.dangerBg,
                  iconColor: colors.danger,
                  title: 'Xóa hồ sơ',
                  subtitle: 'Xóa mềm, không hiển thị trong danh sách.',
                  titleColor: colors.textPrimary,
                  onTap: () => select(PartnerDetailAction.delete),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VSpacing.space4,
                  VSpacing.space3,
                  VSpacing.space4,
                  VSpacing.space4,
                ),
                child: VButton(
                  key: const Key('action_sheet_cancel'),
                  label: 'Hủy',
                  variant: VButtonVariant.secondary,
                  foregroundColor: colors.textPrimary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
  });

  final VIcons icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space2,
      ),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VRadius.card),
          side: BorderSide(color: colors.borderDefault),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Row(
              children: [
                VIconBox(
                  icon: icon,
                  size: 44,
                  iconSize: 22,
                  isCircular: true,
                  backgroundColor: iconBackground,
                  iconColor: iconColor,
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        title,
                        variant: VTextVariant.bodyDefault,
                        color: titleColor ?? colors.textPrimary,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: VSpacing.space1),
                      VText(
                        subtitle,
                        style: VTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                VIcon(
                  icon: VIcons.chevronRight,
                  color: colors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
