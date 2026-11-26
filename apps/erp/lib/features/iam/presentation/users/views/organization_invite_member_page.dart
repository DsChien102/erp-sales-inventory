import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/config/wide_layout.dart';

import '../../../../../../core/session/session_controller.dart';
import '../../../data/invitation_repository.dart';
import '../../shared/iam_load_status.dart';
import '../../shared/iam_role_label_mapper.dart';
import '../../shared/idempotency_key_factory.dart';
import '../bloc/organization_invite_member_cubit.dart';
import '../bloc/organization_invite_member_state.dart';
import '../invitation_role_options_source.dart';
import '../invitation_role_options.dart';
import '../widgets/invite_narrow.dart';
import '../widgets/invite_wide.dart';
import '../widgets/role_radio_list.dart';

/// Trang Mời thành viên (TA-D-03 / S7).
class OrganizationInviteMemberPage extends StatelessWidget {
  const OrganizationInviteMemberPage({
    super.key,
    this.session,
    this.invitations,
    this.roleOptionsSource,
    this.keyFactory,
    this.cubit,
  });

  final SessionController? session;
  final InvitationRepository? invitations;
  final InvitationRoleOptionsSource? roleOptionsSource;
  final IdempotencyKeyFactory? keyFactory;
  final OrganizationInviteMemberCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _InviteMemberView(),
      );
    }
    assert(
      session != null && invitations != null,
      'OrganizationInviteMemberPage requires session + invitations or cubit',
    );
    final repository = invitations!;
    return BlocProvider(
      create: (_) => OrganizationInviteMemberCubit(
        session: session!,
        invitations: repository,
        roleOptionsSource:
            roleOptionsSource ?? IamModuleInvitationRoleOptionsSource(invitations: repository),
        keyFactory: keyFactory ?? const UuidIdempotencyKeyFactory(),
      )..loadRoleOptions(),
      child: const _InviteMemberView(),
    );
  }
}

class _InviteMemberView extends StatefulWidget {
  const _InviteMemberView();

  @override
  State<_InviteMemberView> createState() => _InviteMemberViewState();
}

class _InviteMemberViewState extends State<_InviteMemberView> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit(BuildContext context) async {
    final cubit = context.read<OrganizationInviteMemberCubit>();
    await cubit.submit();
    if (!context.mounted) return;
    final state = cubit.state;
    if (state.failure != null) {
      VToast.show(
        context,
        title: 'Không gửi được lời mời',
        message: state.failure!.message,
        type: VToastType.danger,
      );
      return;
    }
    final created = state.createdInvitation;
    if (created == null) return;

    if (state.deliveryWarning) {
      VToast.show(
        context,
        title: 'Đã tạo lời mời',
        message: 'Email chưa gửi được. Bạn có thể gửi lại từ chi tiết lời mời.',
        type: VToastType.warning,
      );
    } else {
      VToast.show(
        context,
        title: 'Đã gửi lời mời thành công.',
        message: '',
        type: VToastType.success,
      );
    }

    try {
      await context.push('/more/users/invitations/${created.invitationId}');
      if (context.mounted) {
        context.pop(true);
      }
    } catch (_) {
      // Widget tests / no GoRouter: keep page so success toast remains visible.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocConsumer<OrganizationInviteMemberCubit, OrganizationInviteMemberState>(
      listenWhen: (p, c) => p.email != c.email,
      listener: (context, state) {
        if (_emailController.text != state.email) {
          _emailController.value = TextEditingValue(
            text: state.email,
            selection: TextSelection.collapsed(offset: state.email.length),
          );
        }
      },
      builder: (context, state) {
        if (state.status == IamLoadStatus.loading || state.status == IamLoadStatus.initial) {
          return const VPageScaffold(
            title: 'Mời thành viên',
            body: Center(child: VLoading(size: 40)),
          );
        }

        if ((state.status == IamLoadStatus.failure || state.status == IamLoadStatus.success) &&
            state.roleOptions.isEmpty) {
          return VPageScaffold(
            title: 'Mời thành viên',
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: VText(
                        state.status == IamLoadStatus.failure
                            ? 'Không tải được danh sách vai trò'
                            : 'Chưa có vai trò để mời',
                        variant: VTextVariant.headingH4,
                      ),
                    ),
                    const VGap.sm(),
                    VText(
                      state.failure?.message ?? 'Không tải được danh sách vai trò',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                      textAlign: TextAlign.center,
                    ),
                    const VGap.lg(),
                    VButton(
                      label: 'Thử lại',
                      onPressed: () =>
                          context.read<OrganizationInviteMemberCubit>().loadRoleOptions(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final canSubmit = !state.isSubmitting;
        final wide = isWideLayout(context);
        final choices = [
          for (final option in state.roleOptions)
            RoleChoice(
              id: option.roleId,
              title: option.label,
              description: IamRoleLabelMapper.description(option.label),
            ),
        ];

        return VPageScaffold(
          title: 'Mời thành viên',
          bottomBar: Container(
            padding: const EdgeInsets.all(VSpacing.screenMobile),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                top: BorderSide(color: colors.borderDefault),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: VButton(
                      label: 'Hủy',
                      variant: VButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: state.isSubmitting
                          ? null
                          : () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const VGap.horizontalSm(),
                  Expanded(
                    child: VButton(
                      label: state.isSubmitting ? 'Đang gửi...' : 'Gửi lời mời',
                      variant: VButtonVariant.primary,
                      tone: VComponentTone.primary,
                      fullWidth: true,
                      onPressed: canSubmit ? () => _onSubmit(context) : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: ColoredBox(
            color: colors.surfaceAlt,
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: wide
                  ? InviteWide(
                      state: state,
                      emailController: _emailController,
                      choices: choices,
                      onEmailChanged:
                          context.read<OrganizationInviteMemberCubit>().emailChanged,
                      onRoleSelected:
                          context.read<OrganizationInviteMemberCubit>().roleSelected,
                    )
                  : InviteNarrow(
                      state: state,
                      emailController: _emailController,
                      choices: choices,
                      onEmailChanged:
                          context.read<OrganizationInviteMemberCubit>().emailChanged,
                      onRoleSelected:
                          context.read<OrganizationInviteMemberCubit>().roleSelected,
                    ),
            ),
          ),
        );
      },
    );
  }
}
