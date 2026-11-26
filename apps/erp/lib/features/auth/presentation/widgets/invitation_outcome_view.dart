import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/config/wide_layout.dart';
import 'package:erp/core/widgets/flow/flow_layout.dart';
import 'package:flutter/material.dart';

import '../../logic/invitation_acceptance_state.dart';

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
    final wide = isWideLayout(context);
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

    final actions = <Widget>[
      if (isAccepted && onEnterWorkspace != null)
        VButton(
          label: 'Vào không gian làm việc',
          fullWidth: true,
          onPressed: onEnterWorkspace,
        ),
      if (!isAccepted && onEnterOtherToken != null)
        VButton(
          label: 'Nhập mã khác',
          fullWidth: true,
          onPressed: onEnterOtherToken,
        ),
      if (step == InvitationAcceptanceStep.blocked && onRetryLater != null) ...[
        const VGap.sm(),
        VButton(
          label: 'Thử lại sau',
          variant: VButtonVariant.secondary,
          fullWidth: true,
          onPressed: onRetryLater,
        ),
      ],
    ];

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: wide
            ? Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(VSpacing.screenMobile),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          child: VText(
                            title,
                            variant: VTextVariant.headingH3,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const VGap.sm(),
                        VText(
                          body,
                          variant: VTextVariant.bodyDefault,
                          color: colors.textSecondary,
                        ),
                        const VGap.lg(),
                        ...actions,
                      ],
                    ),
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Padding(
                            padding: const EdgeInsets.all(
                              VSpacing.screenMobile,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Spacer(),
                                Center(
                                  child: FlowIcon.large(
                                    isDeclined ? VIcons.close : VIcons.warning,
                                    tone: isDeclined
                                        ? FlowIconTone.neutral
                                        : FlowIconTone.warning,
                                  ),
                                ),
                                const VGap.lg(),
                                Semantics(
                                  header: true,
                                  child: VText(
                                    title,
                                    variant: VTextVariant.headingH2,
                                    color: colors.textPrimary,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const VGap.sm(),
                                VText(
                                  body,
                                  variant: VTextVariant.bodyDefault,
                                  color: colors.textSecondary,
                                  textAlign: TextAlign.center,
                                ),
                                const Spacer(),
                                const VGap.lg(),
                                ...actions,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
