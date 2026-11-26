import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/config/wide_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/invitation_repository.dart';
import '../../shared/iam_action_tile.dart';
import '../../shared/iam_load_status.dart';
import '../../shared/idempotency_key_factory.dart';
import '../bloc/organization_invitation_detail_cubit.dart';
import '../bloc/organization_invitation_detail_state.dart';
import '../mappers/invitation_ui_mapper.dart';
import '../widgets/invitation_detail_narrow.dart';
import '../widgets/invitation_detail_wide.dart';
import '../widgets/revoke_invitation_bottom_sheet.dart';
import '../widgets/user_list_card.dart';

/// Chi tiết lời mời — loads by [invitationId] via [InvitationRepository.getInvitation].
class OrganizationInvitationDetailPage extends StatelessWidget {
  const OrganizationInvitationDetailPage({
    super.key,
    required this.invitationId,
    this.invitations,
    this.keyFactory,
    this.clock,
    this.cubit,
    this.onMutated,
  });

  final String invitationId;
  final InvitationRepository? invitations;
  final IdempotencyKeyFactory? keyFactory;
  final DateTime Function()? clock;
  final OrganizationInvitationDetailCubit? cubit;
  final VoidCallback? onMutated;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _InvitationDetailView(clock: clock, onMutated: onMutated),
      );
    }
    assert(
      invitations != null,
      'OrganizationInvitationDetailPage requires invitations or cubit',
    );
    return BlocProvider(
      create: (_) => OrganizationInvitationDetailCubit(
        invitationId: invitationId,
        invitations: invitations!,
        keyFactory: keyFactory ?? const UuidIdempotencyKeyFactory(),
      )..load(),
      child: _InvitationDetailView(clock: clock, onMutated: onMutated),
    );
  }
}

class _InvitationDetailView extends StatelessWidget {
  const _InvitationDetailView({
    this.clock,
    this.onMutated,
  });

  final DateTime Function()? clock;
  final VoidCallback? onMutated;

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);

    return BlocConsumer<OrganizationInvitationDetailCubit,
        OrganizationInvitationDetailState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure ||
          previous.successMessage != current.successMessage ||
          previous.deliveryWarning != current.deliveryWarning,
      listener: (context, state) {
        final failure = state.failure;
        if (failure != null) {
          VToast.show(
            context,
            title: failure.requiresReload
                ? 'Dữ liệu đã thay đổi'
                : 'Không thực hiện được',
            message: failure.message,
            type: failure.requiresReload
                ? VToastType.warning
                : VToastType.danger,
          );
          context.read<OrganizationInvitationDetailCubit>().clearFeedback();
          return;
        }
        final message = state.successMessage;
        if (message != null) {
          VToast.show(
            context,
            title: state.deliveryWarning ? 'Cảnh báo gửi email' : 'Thành công',
            message: message,
            type: state.deliveryWarning ? VToastType.warning : VToastType.success,
          );
          onMutated?.call();
          context.read<OrganizationInvitationDetailCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        if (state.status == IamLoadStatus.loading ||
            state.status == IamLoadStatus.initial) {
          return const VPageScaffold(
            title: 'Chi tiết lời mời',
            showBackButton: true,
            body: Center(child: VLoading(size: 40)),
          );
        }

        if (state.status == IamLoadStatus.failure || state.invitation == null) {
          final colors = context.vColors;
          return VPageScaffold(
            title: 'Chi tiết lời mời',
            showBackButton: true,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: const VText(
                        'Không tải được lời mời',
                        variant: VTextVariant.headingH4,
                      ),
                    ),
                    const VGap.sm(),
                    VText(
                      state.failure?.message ?? 'Đã xảy ra lỗi',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                      textAlign: TextAlign.center,
                    ),
                    const VGap.lg(),
                    VButton(
                      label: 'Thử lại',
                      onPressed: () => context
                          .read<OrganizationInvitationDetailCubit>()
                          .load(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final now = (clock ?? (() => DateTime.now().toUtc()))();
        final invitation = InvitationUiMapper.fromDetail(
          state.invitation!,
          nowUtc: now,
        );
        final (badgeLabel, badgeTone) =
            invitationStatusBadge(invitation.status);
        final colors = context.vColors;
        final cubit = context.read<OrganizationInvitationDetailCubit>();

        return VPageScaffold(
          title: 'Chi tiết lời mời',
          showBackButton: true,
          body: ColoredBox(
            color: colors.surfaceAlt,
            child: wide
                ? InvitationDetailWide(
                    invitation: invitation,
                    statusLabel: badgeLabel,
                    statusTone: badgeTone,
                    onResend: state.canMutate ? () => cubit.resend() : null,
                    onRevoke: state.canMutate
                        ? () => _openRevokeSheet(context, cubit)
                        : null,
                    busy: state.activeMutation,
                  )
                : InvitationDetailNarrow(
                    invitation: invitation,
                    statusLabel: badgeLabel,
                    statusTone: badgeTone,
                  ),
          ),
          bottomBar: !wide && state.canMutate
              ? Container(
                  padding: const EdgeInsets.all(VSpacing.screenMobile),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(
                      top: BorderSide(color: colors.borderDefault),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: VButton(
                      label: 'Thao tác',
                      trailing: VIcons.chevronUp,
                      variant: VButtonVariant.primary,
                      tone: VComponentTone.primary,
                      fullWidth: true,
                      isLoading: state.isSubmitting,
                      onPressed: state.isSubmitting
                          ? null
                          : () => _showActionBottomSheet(context),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  void _showActionBottomSheet(BuildContext context) {
    final cubit = context.read<OrganizationInvitationDetailCubit>();
    showVAdaptiveSheet(
      context: context,
      title: 'Thao tác lời mời',
      child: Builder(
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.all(VSpacing.screenMobile),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IamActionTile(
                icon: VIcons.refresh,
                title: 'Gửi lại lời mời',
                subtitle: 'Gửi lại email đến người nhận',
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await cubit.resend();
                },
              ),
              const VGap.sm(),
              IamActionTile(
                icon: VIcons.delete,
                title: 'Thu hồi lời mời',
                subtitle: 'Người nhận không thể tiếp tục tham gia',
                isDanger: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openRevokeSheet(context, cubit);
                },
              ),
              const VGap.md(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openRevokeSheet(
    BuildContext context,
    OrganizationInvitationDetailCubit cubit,
  ) async {
    final revoked = await showRevokeInvitationBottomSheet(
      context: context,
      onRevoke: (reason) async {
        await cubit.revoke(reason: reason);
        return cubit.state.failure == null &&
            cubit.state.invitation?.status == 'revoked';
      },
    );
    if (revoked == true && context.mounted) {
      VToast.show(
        context,
        title: 'Đã thu hồi lời mời.',
        message: 'Đã thu hồi lời mời.',
        type: VToastType.success,
      );
      onMutated?.call();
      if (isWideLayout(context)) {
        try {
          context.go('/more/users');
        } catch (_) {}
        return;
      }
      try {
        context.pop(true);
      } catch (_) {
        // Widget tests / no GoRouter.
      }
    }
  }
}
