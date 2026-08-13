import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/iam_load_status.dart';
import '../../shared/idempotency_key_factory.dart';
import '../bloc/organization_invite_member_cubit.dart';
import '../bloc/organization_invite_member_state.dart';
import '../iam_module_invitation_role_options_source.dart';
import '../invitation_role_options.dart';

/// Trang Mời thành viên (TA-D-03 / S7).
class OrganizationInviteMemberPage extends StatelessWidget {
  const OrganizationInviteMemberPage({
    super.key,
    this.iamModule,
    this.executionContext,
    this.roleOptionsSource,
    this.keyFactory,
    this.cubit,
  });

  final IIamModule? iamModule;
  final IExecutionContext? executionContext;
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
      iamModule != null && executionContext != null,
      'OrganizationInviteMemberPage requires iamModule + executionContext or cubit',
    );
    final module = iamModule!;
    return BlocProvider(
      create: (_) => OrganizationInviteMemberCubit(
        iamModule: module,
        executionContext: executionContext!,
        roleOptionsSource:
            roleOptionsSource ??
            IamModuleInvitationRoleOptionsSource(iamModule: module),
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

    return BlocConsumer<OrganizationInviteMemberCubit,
        OrganizationInviteMemberState>(
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
        if (state.status == IamLoadStatus.loading ||
            state.status == IamLoadStatus.initial) {
          return const VPageScaffold(
            title: 'Mời thành viên',
            body: Center(child: VLoading(size: 40)),
          );
        }

        if ((state.status == IamLoadStatus.failure ||
                state.status == IamLoadStatus.success) &&
            state.roleOptions.isEmpty) {
          return VPageScaffold(
            title: 'Mời thành viên',
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VText(
                      state.status == IamLoadStatus.failure
                          ? 'Không tải được danh sách vai trò'
                          : 'Chưa có vai trò để mời',
                      variant: VTextVariant.headingH4,
                    ),
                    const VGap.sm(),
                    VText(
                      state.failure?.message ??
                          'Danh sách vai trò trống. Kiểm tra catalog '
                              'iam.role_definitions trên DB rồi thử lại.',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                      textAlign: TextAlign.center,
                    ),
                    const VGap.lg(),
                    VButton(
                      label: 'Thử lại',
                      onPressed: () => context
                          .read<OrganizationInviteMemberCubit>()
                          .loadRoleOptions(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final canSubmit = state.email.trim().isNotEmpty &&
            state.selectedRoleId != null &&
            !state.isSubmitting;

        return VPageScaffold(
          title: 'Mời thành viên',
          bottomBar: Padding(
            padding: const EdgeInsets.all(VSpacing.screenMobile),
            child: Row(
              children: [
                Expanded(
                  child: VButton(
                    label: 'Hủy',
                    variant: VButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: state.isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const VGap.horizontalSm(),
                Expanded(
                  child: VButton(
                    label: state.isSubmitting ? 'Đang gửi...' : 'Gửi lời mời',
                    variant: VButtonVariant.primary,
                    tone: VComponentTone.success,
                    fullWidth: true,
                    onPressed: canSubmit ? () => _onSubmit(context) : null,
                  ),
                ),
              ],
            ),
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: ListView(
              padding: const EdgeInsets.all(VSpacing.screenMobile),
              children: [
                VText(
                  'Người nhận phải đăng nhập đúng email. Lời mời sẽ hết hạn sau 7 ngày.',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
                const VGap.md(),
                VTextField(
                  label: 'Email',
                  isRequired: true,
                  hintText: 'nhanvien@minhphat.vn',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  helperText: 'Người nhận phải đăng nhập đúng email.',
                  onChanged: context
                      .read<OrganizationInviteMemberCubit>()
                      .emailChanged,
                ),
                const VGap.md(),
                VSelect<String>(
                  label: 'Vai trò ban đầu',
                  hintText: 'Chọn vai trò',
                  value: state.selectedRoleId,
                  items: [
                    for (final option in state.roleOptions)
                      DropdownMenuItem(
                        value: option.roleId,
                        child: VText(option.label),
                      ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      context
                          .read<OrganizationInviteMemberCubit>()
                          .roleSelected(val);
                    }
                  },
                ),
                const VGap.xs(),
                VText(
                  'Vai trò có thể thay đổi sau khi tham gia.',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
