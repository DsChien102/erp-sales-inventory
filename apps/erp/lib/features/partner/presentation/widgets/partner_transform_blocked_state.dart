import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';

/// Blocked outcomes for transform flow (ready to map from command failures).
enum PartnerTransformBlockedKind {
  noPermission,
  staleData,
}

/// Maps application blocked codes used by transform command failures.
PartnerTransformBlockedKind? partnerTransformBlockedKindFromCode(String code) {
  return switch (code) {
    PartnerErrorCodes.noPermission => PartnerTransformBlockedKind.noPermission,
    PartnerErrorCodes.stateChanged => PartnerTransformBlockedKind.staleData,
    _ => null,
  };
}

/// Empty / blocked screens for transform: no permission + stale data.
class PartnerTransformBlockedState extends StatelessWidget {
  const PartnerTransformBlockedState.noPermission({
    super.key,
    required this.onActionPressed,
  }) : kind = PartnerTransformBlockedKind.noPermission;

  const PartnerTransformBlockedState.staleData({
    super.key,
    required this.onActionPressed,
  }) : kind = PartnerTransformBlockedKind.staleData;

  const PartnerTransformBlockedState({
    super.key,
    required this.kind,
    required this.onActionPressed,
  });

  final PartnerTransformBlockedKind kind;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isNoPermission = kind == PartnerTransformBlockedKind.noPermission;

    return Padding(
      key: Key(
        isNoPermission ? 'transform_blocked_no_permission' : 'transform_blocked_stale_data',
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space6,
        vertical: VSpacing.space8,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isNoPermission) const _NoPermissionIllustration() else const _StaleDataIllustration(),
          const SizedBox(height: VSpacing.space6),
          VText(
            isNoPermission ? 'Không có quyền chuyển đổi' : 'Dữ liệu đã thay đổi',
            variant: VTextVariant.headingH3,
            color: colors.textPrimary,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: VSpacing.space3),
          VText(
            isNoPermission
                ? 'Bạn không có quyền thực hiện chuyển đổi hồ sơ này.'
                : 'Hồ sơ đã được cập nhật ở nơi khác. Vui lòng tải lại để tiếp tục.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.4),
          ),
          const SizedBox(height: VSpacing.space8),
          SizedBox(
            width: double.infinity,
            child: VButton(
              key: Key(
                isNoPermission ? 'transform_blocked_back' : 'transform_blocked_reload',
              ),
              label: isNoPermission ? 'Quay lại' : 'Tải lại',
              onPressed: onActionPressed,
              variant: VButtonVariant.secondary,
              foregroundColor: colors.success,
              size: VButtonSize.medium,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPermissionIllustration extends StatelessWidget {
  const _NoPermissionIllustration();

  @override
  Widget build(BuildContext context) {
    final muted = context.vColors.textMuted;
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VIcon(
            icon: VIcons.shield,
            size: 120,
            color: muted.withValues(alpha: 0.28),
          ),
          VIcon(
            icon: VIcons.add,
            size: 36,
            color: muted.withValues(alpha: 0.55),
          ),
        ],
      ),
    );
  }
}

class _StaleDataIllustration extends StatelessWidget {
  const _StaleDataIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final muted = colors.textMuted;
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VIcon(
            icon: VIcons.cloud,
            size: 110,
            color: muted.withValues(alpha: 0.28),
          ),
          Positioned(
            bottom: 28,
            child: VIcon(
              icon: VIcons.warning,
              size: 48,
              color: colors.danger.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}
