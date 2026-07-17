import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';

/// D-10 feedback kinds — no permission / stale data / generic error.
enum PartnerOperationFeedbackKind {
  noPermission,
  sourceChanged,
  error,
}

/// Maps common [PartnerBlockedCodes] to a D-10 feedback kind.
PartnerOperationFeedbackKind? partnerOperationFeedbackKindFromCode(String code) {
  return switch (code) {
    PartnerBlockedCodes.noPermission => PartnerOperationFeedbackKind.noPermission,
    PartnerBlockedCodes.stateChanged => PartnerOperationFeedbackKind.sourceChanged,
    PartnerBlockedCodes.systemError => PartnerOperationFeedbackKind.error,
    _ => null,
  };
}

/// Reusable full-body feedback screens (SG-07 / D-10).
///
/// Use named constructors, or [PartnerOperationFeedbackKind] + [onActionPressed].
class PartnerOperationFeedbackState extends StatelessWidget {
  const PartnerOperationFeedbackState.noPermission({
    super.key,
    required this.onActionPressed,
    this.actionLabel,
    this.title,
    this.description,
  }) : kind = PartnerOperationFeedbackKind.noPermission;

  const PartnerOperationFeedbackState.sourceChanged({
    super.key,
    required this.onActionPressed,
    this.actionLabel,
    this.title,
    this.description,
  }) : kind = PartnerOperationFeedbackKind.sourceChanged;

  const PartnerOperationFeedbackState.error({
    super.key,
    required this.onActionPressed,
    this.actionLabel,
    this.title,
    this.description,
  }) : kind = PartnerOperationFeedbackKind.error;

  const PartnerOperationFeedbackState({
    super.key,
    required this.kind,
    required this.onActionPressed,
    this.actionLabel,
    this.title,
    this.description,
  });

  final PartnerOperationFeedbackKind kind;
  final VoidCallback onActionPressed;

  /// Override default CTA label when needed.
  final String? actionLabel;

  /// Override default title when needed.
  final String? title;

  /// Override default description when needed.
  final String? description;

  static const _defaults = {
    PartnerOperationFeedbackKind.noPermission: (
      title: 'Không có quyền thực hiện thao tác',
      description: 'Bạn không có quyền xem hoặc thực hiện thao tác này.',
      actionLabel: 'Quay lại',
      key: 'wgt_e02_d10_no_permission',
      actionKey: 'feedback_no_permission_back',
    ),
    PartnerOperationFeedbackKind.sourceChanged: (
      title: 'Dữ liệu đã thay đổi',
      description:
          'Hồ sơ đã được cập nhật ở nơi khác. Vui lòng tải lại để tiếp tục.',
      actionLabel: 'Tải lại',
      key: 'wgt_e02_d10_source_changed',
      actionKey: 'feedback_source_changed_reload',
    ),
    PartnerOperationFeedbackKind.error: (
      title: 'Đã xảy ra lỗi',
      description: 'Vui lòng thử lại sau.',
      actionLabel: 'Thử lại',
      key: 'wgt_e02_d10_error',
      actionKey: 'feedback_error_retry',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final defaults = _defaults[kind]!;
    final resolvedTitle = title ?? defaults.title;
    final resolvedDescription = description ?? defaults.description;
    final resolvedAction = actionLabel ?? defaults.actionLabel;

    return Padding(
      key: Key(defaults.key),
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space6,
        vertical: VSpacing.space8,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          switch (kind) {
            PartnerOperationFeedbackKind.noPermission =>
              const _NoPermissionIllustration(),
            PartnerOperationFeedbackKind.sourceChanged =>
              const _SourceChangedIllustration(),
            PartnerOperationFeedbackKind.error => const _ErrorIllustration(),
          },
          const SizedBox(height: VSpacing.space6),
          Text(
            resolvedTitle,
            style: VTypography.headingH3.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VSpacing.space3),
          Text(
            resolvedDescription,
            style: VTypography.bodyDefault.copyWith(
              color: colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VSpacing.space8),
          SizedBox(
            width: 220,
            child: VButton(
              key: Key(defaults.actionKey),
              label: resolvedAction,
              onPressed: onActionPressed,
              variant: VButtonVariant.outline,
              foregroundColor: colors.success,
              size: VButtonSize.medium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows D-10 feedback as a full-screen dialog route (optional entry point).
Future<void> showPartnerOperationFeedbackDialog(
  BuildContext context, {
  required PartnerOperationFeedbackKind kind,
  required VoidCallback onActionPressed,
  String? title,
  String? description,
  String? actionLabel,
  bool barrierDismissible = false,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      return Dialog.fullscreen(
        backgroundColor: dialogContext.vColors.surface,
        child: SafeArea(
          child: PartnerOperationFeedbackState(
            kind: kind,
            title: title,
            description: description,
            actionLabel: actionLabel,
            onActionPressed: () {
              Navigator.of(dialogContext).pop();
              onActionPressed();
            },
          ),
        ),
      );
    },
  );
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
            icon: VIcons.lock,
            size: 36,
            color: muted.withValues(alpha: 0.75),
          ),
        ],
      ),
    );
  }
}

class _SourceChangedIllustration extends StatelessWidget {
  const _SourceChangedIllustration();

  @override
  Widget build(BuildContext context) {
    final muted = context.vColors.textMuted;
    return SizedBox(
      width: 140,
      height: 140,
      child: VIcon(
        icon: VIcons.refresh,
        size: 88,
        color: muted.withValues(alpha: 0.55),
      ),
    );
  }
}

class _ErrorIllustration extends StatelessWidget {
  const _ErrorIllustration();

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
            icon: VIcons.cloud,
            size: 110,
            color: muted.withValues(alpha: 0.28),
          ),
          Positioned(
            bottom: 28,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: VColors.danger,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                '!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
