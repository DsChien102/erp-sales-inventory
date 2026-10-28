import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/iam/iam_codes.dart';

import '../../../data/member_repository.dart';
import '../../../data/models/tenant_member.dart';
import '../../shared/iam_load_status.dart';
import '../bloc/organization_member_detail_cubit.dart';
import '../bloc/organization_member_detail_state.dart';
import '../mappers/member_ui_mapper.dart';
import '../widgets/deactivate_membership_bottom_sheet.dart';
import '../widgets/member_detail_body.dart';
import '../widgets/member_lifecycle_actions.dart';
import '../widgets/reactivate_membership_bottom_sheet.dart';
import '../widgets/remove_membership_bottom_sheet.dart';

import '../models/user_ui_model.dart';
import 'organization_select_role_page.dart';

/// Chi tiết thành viên — loads by [membershipId] via [MemberRepository.getMember].
class OrganizationMemberDetailPage extends StatelessWidget {
  const OrganizationMemberDetailPage({
    super.key,
    required this.membershipId,
    this.members,
    this.cubit,
  });

  final String membershipId;
  final MemberRepository? members;
  final OrganizationMemberDetailCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _MemberDetailView(),
      );
    }
    assert(
      members != null,
      'OrganizationMemberDetailPage requires members or cubit',
    );
    return BlocProvider(
      create: (_) => OrganizationMemberDetailCubit(
        membershipId: membershipId,
        members: members!,
      )..load(),
      child: const _MemberDetailView(),
    );
  }
}

class _MemberDetailView extends StatelessWidget {
  const _MemberDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrganizationMemberDetailCubit,
        OrganizationMemberDetailState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        final failure = state.failure;
        if (failure != null) {
          final isProtected =
              failure.code == IamBlockedCodes.lastOwnerProtected;
          VToast.show(
            context,
            title: isProtected
                ? 'Không thể thực hiện'
                : failure.requiresReload
                    ? 'Dữ liệu đã thay đổi'
                    : 'Không thực hiện được',
            message: failure.message,
            type: isProtected || failure.requiresReload
                ? VToastType.warning
                : VToastType.danger,
          );
          context.read<OrganizationMemberDetailCubit>().clearFeedback();
          return;
        }
        final message = state.successMessage;
        if (message != null) {
          VToast.show(
            context,
            title: message,
            message: '',
            type: VToastType.success,
          );
          context.read<OrganizationMemberDetailCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        if (state.status == IamLoadStatus.loading ||
            state.status == IamLoadStatus.initial) {
          return const VPageScaffold(
            title: 'Chi tiết thành viên',
            body: Center(child: VLoading(size: 40)),
          );
        }

        if (state.status == IamLoadStatus.failure || state.member == null) {
          final colors = context.vColors;
          return VPageScaffold(
            title: 'Chi tiết thành viên',
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: const VText(
                        'Không tải được thành viên',
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
                          .read<OrganizationMemberDetailCubit>()
                          .load(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final member = MemberUiMapper.fromDetail(state.member!);
        return VPageScaffold(
          title: 'Chi tiết thành viên',
          bottomBar: state.hasLifecycleActions
              ? Padding(
                  padding: const EdgeInsets.all(VSpacing.screenMobile),
                  child: VButton(
                    label: 'Thao tác',
                    trailing: VIcons.chevronUp,
                    variant: VButtonVariant.primary,
                    tone: VComponentTone.success,
                    fullWidth: true,
                    isLoading: state.isSubmitting,
                    onPressed: state.isSubmitting
                        ? null
                        : () => _openActions(context, state),
                  ),
                )
              : null,
          body: MemberDetailBody(
            member: member,
            detailStatus: state.member!.status,
          ),
        );
      },
    );
  }

  void _openActions(
    BuildContext context,
    OrganizationMemberDetailState state,
  ) {
    final cubit = context.read<OrganizationMemberDetailCubit>();
    final member = MemberUiMapper.fromDetail(state.member!);
    showMemberLifecycleActionsBottomSheet(
      context: context,
      state: state,
      onChangeRole: () => _openChangeRole(context, member, cubit),
      onDeactivate: () => _confirmDeactivate(context, cubit),
      onReactivate: () => _confirmReactivate(context, cubit),
      onRemove: () => _confirmRemove(context, cubit),
    );
  }

  Future<void> _openChangeRole(
    BuildContext context,
    MemberUiModel member,
    OrganizationMemberDetailCubit cubit,
  ) async {
    final selectedRoleCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => OrganizationSelectRolePage(member: member),
      ),
    );
    if (selectedRoleCode != null && context.mounted) {
      await cubit.changeRole(selectedRoleCode);
    }
  }

  Future<void> _confirmDeactivate(
    BuildContext context,
    OrganizationMemberDetailCubit cubit,
  ) async {
    await showDeactivateMembershipBottomSheet(
      context: context,
      onConfirm: () async {
        await cubit.deactivate();
        return cubit.state.failure == null &&
            cubit.state.member?.status == MembershipStatus.inactive;
      },
    );
  }

  Future<void> _confirmReactivate(
    BuildContext context,
    OrganizationMemberDetailCubit cubit,
  ) async {
    await showReactivateMembershipBottomSheet(
      context: context,
      onConfirm: () async {
        await cubit.reactivate();
        return cubit.state.failure == null &&
            cubit.state.member?.status == MembershipStatus.active;
      },
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    OrganizationMemberDetailCubit cubit,
  ) async {
    await showRemoveMembershipBottomSheet(
      context: context,
      onConfirm: () async {
        await cubit.remove();
        return cubit.state.failure == null &&
            cubit.state.member?.status == MembershipStatus.removed;
      },
    );
  }
}
