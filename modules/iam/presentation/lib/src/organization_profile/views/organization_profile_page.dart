import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../mock/organization_profile_mock_data.dart';
import '../models/organization_profile_ui_model.dart';
import '../widgets/organization_profile_actions_bottom_sheet.dart';
import '../../organizations/widgets/organization_empty_view.dart';

/// Trang Hồ sơ tổ chức (TA-D-01) tuân thủ 100% Design System với VPageScaffold và VBadge.
class OrganizationProfilePage extends StatelessWidget {
  final OrganizationProfileUiModel profile;
  final bool hasPermission;

  const OrganizationProfilePage({
    super.key,
    this.profile = OrganizationProfileMockData.sampleProfile,
    this.hasPermission = true,
  });

  void _openActionsBottomSheet(BuildContext context) {
    showVBottomSheet(
      context: context,
      child: OrganizationProfileActionsBottomSheet(
        hasLegalProfile: profile.hasLegalProfile,
        onEditInfoTap: () {
          context.push('/more/organization-profile/edit');
        },
        onAddLegalTap: () {
          context.push('/more/organization-profile/legal');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission) {
      return VPageScaffold(
        title: 'Hồ sơ tổ chức',
        body: OrganizationEmptyView(
          type: OrganizationEmptyStateType.unauthorized,
          onAction: () => Navigator.of(context).pop(),
        ),
      );
    }

    final colors = context.vColors;

    return VPageScaffold(
      title: 'Hồ sơ tổ chức',
      bottomBar: Padding(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        child: VButton(
          label: 'Thao tác',
          trailingIcon: VIcon(
            icon: VIcons.chevronUp,
            color: colors.surface,
          ),
          variant: VButtonVariant.primary,
          tone: VComponentTone.success,
          fullWidth: true,
          onPressed: () => _openActionsBottomSheet(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        children: [
          // Header Card
          VCard(
            backgroundColor: colors.surface,
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Row(
              children: [
                VIcon(
                  icon: VIcons.apartment,
                  size: 24,
                  color: colors.textPrimary,
                ),
                const VGap.horizontalSm(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VText(
                        profile.name,
                        variant: VTextVariant.headingH4,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const VGap.xs(),
                      VText(
                        profile.statusDescription,
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
                VBadge(
                  label: profile.statusLabel,
                  status: VBadgeStatus.success,
                ),
              ],
            ),
          ),
          const VGap.sm(),

          // Section 1: Thông tin tổ chức
          VCard(
            backgroundColor: colors.surface,
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  'Thông tin tổ chức',
                  variant: VTextVariant.headingH4,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const VGap.md(),
                _InfoRow(label: 'Tên hiển thị', value: profile.name),
                const VGap.md(),
                _InfoRow(label: 'Điện thoại', value: profile.phone),
                const VGap.md(),
                _InfoRow(label: 'Email', value: profile.email),
                const VGap.md(),
                _InfoRow(label: 'Địa chỉ', value: profile.address),
              ],
            ),
          ),
          const VGap.sm(),

          // Section 2: Hồ sơ pháp lý
          VCard(
            backgroundColor: colors.surface,
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  'Hồ sơ pháp lý',
                  variant: VTextVariant.headingH4,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const VGap.md(),
                Container(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  decoration: BoxDecoration(
                    color: colors.warningBg,
                    borderRadius: BorderRadius.circular(VRadius.card),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VIcon(
                        icon: VIcons.warning,
                        size: 20,
                        color: colors.warning,
                      ),
                      const VGap.horizontalSm(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            VText(
                              profile.legalNoticeTitle,
                              variant: VTextVariant.bodyDefault,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colors.warning,
                              ),
                            ),
                            const VGap.xs(),
                            VText(
                              profile.legalNoticeMessage,
                              variant: VTextVariant.bodySmall,
                              color: colors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(
          label,
          variant: VTextVariant.bodyDefault,
          color: colors.textMuted,
        ),
        Flexible(
          child: VText(
            value,
            variant: VTextVariant.bodyDefault,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
