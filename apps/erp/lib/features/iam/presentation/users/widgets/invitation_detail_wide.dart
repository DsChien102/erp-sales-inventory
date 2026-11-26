import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../shared/detail_layout.dart';
import '../bloc/organization_invitation_detail_state.dart';
import '../models/user_ui_model.dart';
import 'user_list_card.dart';

class InvitationDetailWide extends StatelessWidget {
  const InvitationDetailWide({
    super.key,
    required this.invitation,
    required this.statusLabel,
    required this.statusTone,
    required this.onResend,
    required this.onRevoke,
    required this.busy,
  });

  final InvitationUiModel invitation;
  final String statusLabel;
  final VComponentTone statusTone;
  final VoidCallback? onResend;
  final VoidCallback? onRevoke;
  final InvitationMutation? busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final hasActions = onResend != null || onRevoke != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DetailHeaderWide(
                leading: DetailAvatar(
                  invitationInitial(invitation.email),
                  size: 48,
                ),
                title: invitation.email,
                subtitle: invitation.expiryLabel.isEmpty
                    ? null
                    : invitation.expiryLabel,
              ),
              const SizedBox(height: 24),
              DetailSectionWide(
                title: 'Thông tin lời mời',
                action: VBadge(
                  label: statusLabel,
                  tone: statusTone,
                  variant: VBadgeVariant.soft,
                  isSmall: true,
                ),
                children: [
                  DetailRow(label: 'Vai trò ban đầu', value: invitation.role),
                  DetailRow(label: 'Trạng thái', value: statusLabel),
                  DetailRow(
                    label: 'Giao nhận',
                    value: invitation.deliveryLabel.isEmpty
                        ? '—'
                        : invitation.deliveryLabel,
                  ),
                  if (hasActions)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: colors.borderDefault),
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final twoCols = constraints.maxWidth >= 420;
                          final itemWidth = twoCols
                              ? (constraints.maxWidth - 12) / 2
                              : constraints.maxWidth;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              if (onResend != null)
                                SizedBox(
                                  width: itemWidth,
                                  child: VButton(
                                    label: 'Gửi lại lời mời',
                                    variant: VButtonVariant.secondary,
                                    fullWidth: true,
                                    isLoading:
                                        busy == InvitationMutation.resend,
                                    onPressed: busy != null ? null : onResend,
                                  ),
                                ),
                              if (onRevoke != null)
                                SizedBox(
                                  width: itemWidth,
                                  child: VButton(
                                    label: 'Thu hồi lời mời',
                                    variant: VButtonVariant.secondary,
                                    tone: VComponentTone.danger,
                                    fullWidth: true,
                                    isLoading:
                                        busy == InvitationMutation.revoke,
                                    onPressed: busy != null ? null : onRevoke,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
