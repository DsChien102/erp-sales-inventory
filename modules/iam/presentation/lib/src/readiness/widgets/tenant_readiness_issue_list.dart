import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

import '../tenant_readiness_cta_mapper.dart';

class TenantReadyToActivateCard extends StatelessWidget {
  const TenantReadyToActivateCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VCard(
      backgroundColor: colors.surfaceAlt,
      border: Border.all(color: colors.surfaceAlt),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            'Sẵn sàng kích hoạt',
            variant: VTextVariant.headingH4,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const VGap.xs(),
          VText(
            'Các điều kiện bắt buộc đã hoàn tất. Tổ chức có thể bắt đầu vận hành.',
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class TenantRequiredSetupCard extends StatelessWidget {
  const TenantRequiredSetupCard({
    super.key,
    required this.blockers,
    required this.onIssueTap,
  });

  final List<String> blockers;
  final void Function(String issueCode, String? route) onIssueTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final profileIssue = _firstMatching(_profileIssueCodes);
    final ownerIssue = _firstMatching(_ownerIssueCodes);
    final roleIssue = _firstMatching(_roleIssueCodes);

    return VCard(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            'Điều kiện bắt buộc',
            variant: VTextVariant.headingH4,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const VGap.md(),
          _SetupRequirementTile(
            title: 'Hồ sơ tổ chức',
            subtitle: profileIssue == null ? 'Thông tin cơ bản hợp lệ' : 'Thiếu thông tin',
            issueCode: profileIssue,
            onIssueTap: onIssueTap,
          ),
          const VGap.sm(),
          _SetupRequirementTile(
            title: 'Chủ sở hữu',
            subtitle: ownerIssue == null
                ? 'Đã xác thực'
                : TenantReadinessCtaMapper.labelFor(ownerIssue),
            issueCode: ownerIssue,
            onIssueTap: onIssueTap,
          ),
          const VGap.sm(),
          _SetupRequirementTile(
            title: 'Vai trò vận hành',
            subtitle: roleIssue == null
                ? 'Đã phân quyền'
                : TenantReadinessCtaMapper.labelFor(roleIssue),
            issueCode: roleIssue,
            onIssueTap: onIssueTap,
          ),
        ],
      ),
    );
  }

  String? _firstMatching(Set<String> codes) {
    for (final blocker in blockers) {
      if (codes.contains(blocker)) return blocker;
    }
    return null;
  }
}

class TenantLegalProfileInfoCard extends StatelessWidget {
  const TenantLegalProfileInfoCard({
    super.key,
    required this.isReady,
    required this.hasWarning,
    required this.onIssueTap,
  });

  final bool isReady;
  final bool hasWarning;
  final void Function(String issueCode, String? route) onIssueTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    const issueCode = TenantReadinessIssueCodes.legalProfileMissing;
    return VCard(
      backgroundColor: colors.infoBg,
      border: Border.all(color: colors.infoBg),
      padding: const EdgeInsets.all(VSpacing.space4),
      onTap: hasWarning
          ? () => onIssueTap(
              issueCode,
              TenantReadinessCtaMapper.routeFor(issueCode),
            )
          : null,
      child: Row(
        children: [
          VIcon(
            icon: VIcons.info,
            size: 24,
            color: colors.info,
          ),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  'Hồ sơ pháp lý',
                  variant: VTextVariant.bodyDefault,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.info,
                  ),
                ),
                const VGap.xs(),
                VText(
                  isReady ? 'Một số tính năng pháp lý chưa khả dụng' : 'Chưa khai báo mã số thuế',
                  variant: VTextVariant.bodyDefault,
                  color: colors.textPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupRequirementTile extends StatelessWidget {
  const _SetupRequirementTile({
    required this.title,
    required this.subtitle,
    required this.issueCode,
    required this.onIssueTap,
  });

  final String title;
  final String subtitle;
  final String? issueCode;
  final void Function(String issueCode, String? route) onIssueTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isBlocked = issueCode != null;
    final toneColor = isBlocked ? colors.warning : colors.success;
    final background = isBlocked ? colors.warningBg : colors.successBg;
    final supportHint = issueCode == null || TenantReadinessCtaMapper.routeFor(issueCode!) != null
        ? null
        : TenantReadinessCtaMapper.supportHintFor(issueCode!);

    return VCard(
      backgroundColor: background,
      border: Border.all(color: background),
      padding: const EdgeInsets.all(VSpacing.space4),
      onTap: issueCode == null
          ? null
          : () => onIssueTap(
              issueCode!,
              TenantReadinessCtaMapper.routeFor(issueCode!),
            ),
      child: Row(
        children: [
          VIcon(
            icon: isBlocked ? VIcons.warning : VIcons.success,
            size: 24,
            color: toneColor,
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
                    color: toneColor,
                  ),
                ),
                const VGap.xs(),
                VText(
                  subtitle,
                  variant: VTextVariant.bodyDefault,
                  color: colors.textPrimary,
                ),
                if (supportHint != null) ...[
                  const VGap.xs(),
                  VText(
                    supportHint,
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _profileIssueCodes = {
  TenantReadinessIssueCodes.displayNameMissing,
  TenantReadinessIssueCodes.contactEmailMissingOrInvalid,
  TenantReadinessIssueCodes.contactPhoneMissingOrInvalid,
  TenantReadinessIssueCodes.contactAddressMissing,
};

const _ownerIssueCodes = {
  TenantReadinessIssueCodes.ownerMembershipInvalid,
  TenantReadinessIssueCodes.ownerIdentityInactive,
  TenantReadinessIssueCodes.ownerIdentityUnavailable,
  TenantReadinessIssueCodes.ownerEmailUnverified,
};

const _roleIssueCodes = {
  TenantReadinessIssueCodes.ownerRoleInvalid,
};
