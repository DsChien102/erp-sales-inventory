import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/invitation_acceptance_state.dart';

class InvitationOutcomeView extends StatelessWidget {
  const InvitationOutcomeView({
    super.key,
    required this.step,
    this.message,
    this.onEnterWorkspace,
    this.onEnterOtherToken,
    this.onRetryLater,
  });

  final InvitationAcceptanceStep step;
  final String? message;
  final VoidCallback? onEnterWorkspace;
  final VoidCallback? onEnterOtherToken;
  final VoidCallback? onRetryLater;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isAccepted = step == InvitationAcceptanceStep.accepted;
    final isDeclined = step == InvitationAcceptanceStep.declined;
    final title = isAccepted
        ? 'Đã tham gia tổ chức'
        : isDeclined
        ? 'Đã từ chối lời mời'
        : 'Không thể tiếp tục';
    final body =
        message ??
        (isAccepted
            ? 'Bạn đã trở thành thành viên và có thể vào không gian làm việc.'
            : isDeclined
            ? 'Lời mời đã được từ chối.'
            : 'Mã lời mời không dùng được. Bạn có thể nhập mã khác.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VText(
          title,
          variant: VTextVariant.headingH3,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const VGap.sm(),
        VText(
          body,
          variant: VTextVariant.bodyDefault,
          color: colors.textSecondary,
        ),
        const VGap.lg(),
        if (isAccepted && onEnterWorkspace != null)
          VButton(
            label: 'Vào không gian làm việc',
            fullWidth: true,
            onPressed: onEnterWorkspace,
          ),
        if (!isAccepted && onEnterOtherToken != null) ...[
          VButton(
            label: 'Nhập mã khác',
            fullWidth: true,
            onPressed: onEnterOtherToken,
          ),
        ],
        if (step == InvitationAcceptanceStep.blocked && onRetryLater != null) ...[
          const VGap.sm(),
          VButton(
            label: 'Thử lại sau',
            variant: VButtonVariant.secondary,
            fullWidth: true,
            onPressed: onRetryLater,
          ),
        ],
      ],
    );
  }
}
