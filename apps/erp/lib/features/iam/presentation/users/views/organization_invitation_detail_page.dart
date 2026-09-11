import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/iam_load_status.dart';
import '../../shared/idempotency_key_factory.dart';
import '../bloc/organization_invitation_detail_cubit.dart';
import '../bloc/organization_invitation_detail_state.dart';
import '../mappers/invitation_ui_mapper.dart';
import '../models/user_ui_model.dart';
import '../widgets/revoke_invitation_bottom_sheet.dart';

/// Chi tiết lời mời — loads by [invitationId] via [GetInvitationQuery].
class OrganizationInvitationDetailPage extends StatelessWidget {
  const OrganizationInvitationDetailPage({
    super.key,
    required this.invitationId,
    this.iamModule,
    this.executionContext,
    this.keyFactory,
    this.clock,
    this.cubit,
  });

  final String invitationId;
  final IIamModule? iamModule;
  final IExecutionContext? executionContext;
  final IdempotencyKeyFactory? keyFactory;
  final DateTime Function()? clock;
  final OrganizationInvitationDetailCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _InvitationDetailView(clock: clock),
      );
    }
    assert(
      iamModule != null && executionContext != null,
      'OrganizationInvitationDetailPage requires iamModule + '
      'executionContext or cubit',
    );
    return BlocProvider(
      create: (_) => OrganizationInvitationDetailCubit(
        invitationId: invitationId,
        iamModule: iamModule!,
        executionContext: executionContext!,
        keyFactory: keyFactory ?? const UuidIdempotencyKeyFactory(),
      )..load(),
      child: _InvitationDetailView(clock: clock),
    );
  }
}

class _InvitationDetailView extends StatelessWidget {
  const _InvitationDetailView({this.clock});

  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
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
          context
              .read<OrganizationInvitationDetailCubit>()
              .clearFeedback();
          return;
        }
        final message = state.successMessage;
        if (message != null) {
          VToast.show(
            context,
            title: state.deliveryWarning ? 'Cảnh báo gửi email' : 'Thành công',
            message: message,
            type: state.deliveryWarning
                ? VToastType.warning
                : VToastType.success,
          );
          context
              .read<OrganizationInvitationDetailCubit>()
              .clearFeedback();
        }
      },
      builder: (context, state) {
        if (state.status == IamLoadStatus.loading ||
            state.status == IamLoadStatus.initial) {
          return const VPageScaffold(
            title: 'Chi tiết lời mời',
            body: Center(child: VLoading(size: 40)),
          );
        }

        if (state.status == IamLoadStatus.failure ||
            state.invitation == null) {
          final colors = context.vColors;
          return VPageScaffold(
            title: 'Chi tiết lời mời',
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const VText(
                      'Không tải được lời mời',
                      variant: VTextVariant.headingH4,
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
        final colors = context.vColors;
        final (badgeLabel, badgeStatus) = switch (invitation.status) {
          InvitationStatus.failed => ('Lỗi gửi', VBadgeStatus.danger),
          InvitationStatus.pending => ('Đang chờ', VBadgeStatus.warning),
          InvitationStatus.expiring => ('Sắp hết hạn', VBadgeStatus.danger),
          InvitationStatus.accepted => ('Đã chấp nhận', VBadgeStatus.success),
          InvitationStatus.declined => ('Đã từ chối', VBadgeStatus.cancelled),
          InvitationStatus.revoked => ('Đã thu hồi', VBadgeStatus.cancelled),
          InvitationStatus.expired => ('Hết hạn', VBadgeStatus.locked),
        };

        return VPageScaffold(
          title: 'Chi tiết lời mời',
          body: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.screenMobile,
              vertical: VSpacing.space4,
            ),
            children: [
              VCard(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: VText(
                            invitation.email,
                            variant: VTextVariant.headingH4,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        VBadge(
                          label: badgeLabel,
                          status: badgeStatus,
                          isSmall: true,
                        ),
                      ],
                    ),
                    const VGap.sm(),
                    VText(
                      invitation.statusDetail,
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                    if (invitation.deliveryStatus.isNotEmpty) ...[
                      const VGap.sm(),
                      VText(
                        'Giao nhận: ${invitation.deliveryStatus}',
                        variant: VTextVariant.bodySmall,
                        color: colors.textMuted,
                      ),
                    ],
                    if (state.invitation!.status != 'pending') ...[
                      const VGap.sm(),
                      VText(
                        'Trạng thái: ${state.invitation!.status}',
                        variant: VTextVariant.bodySmall,
                        color: colors.textMuted,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          bottomBar: state.canMutate
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
    showVBottomSheet(
      context: context,
      title: 'Thao tác lời mời',
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionItem(
              icon: VIcons.refresh,
              title: 'Gửi lại lời mời',
              subtitle: 'Gửi lại email đến người nhận',
              onTap: () async {
                Navigator.of(context).pop();
                await cubit.resend();
              },
            ),
            const VGap.sm(),
            _ActionItem(
              icon: VIcons.delete,
              title: 'Thu hồi lời mời',
              subtitle: 'Người nhận không thể tiếp tục tham gia',
              isDanger: true,
              onTap: () {
                Navigator.of(context).pop();
                _openRevokeSheet(context, cubit);
              },
            ),
            const VGap.md(),
          ],
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
      try {
        context.pop(true);
      } catch (_) {
        // Widget tests / no GoRouter.
      }
    }
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  final VIcons icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final bgColor = isDanger ? colors.dangerBg : colors.surface;
    final borderColor = isDanger ? colors.danger : colors.borderDefault;
    final iconColor = isDanger ? colors.danger : colors.textPrimary;
    final titleColor = isDanger ? colors.danger : colors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(VSpacing.space4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(VRadius.card),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            VIcon(icon: icon, size: 22, color: iconColor),
            const VGap.horizontalMd(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    title,
                    variant: VTextVariant.bodyDefault,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const VGap.xs(),
                  VText(
                    subtitle,
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
            VIcon(
              icon: VIcons.chevronRight,
              size: 20,
              color: isDanger ? colors.danger : colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
