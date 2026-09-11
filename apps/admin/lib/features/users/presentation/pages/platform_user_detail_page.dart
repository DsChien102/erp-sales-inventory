import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';

import '../../../../core/di/injection.dart';
import '../bloc/platform_user_detail_cubit.dart';
import '../bloc/platform_user_detail_state.dart';
import '../widgets/platform_user_action_sheet.dart';

class PlatformUserDetailPage extends StatelessWidget {
  const PlatformUserDetailPage({
    super.key,
    required this.userId,
    this.iamModule,
    this.cubit,
  });

  final String userId;

  /// Optional override for widget / E2E tests. Defaults to GetIt [IIamModule].
  final IIamModule? iamModule;
  final PlatformUserDetailCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _PlatformUserDetailView(),
      );
    }
    return BlocProvider(
      create: (_) {
        final created = PlatformUserDetailCubit(
          iamModule: iamModule ?? getIt<IIamModule>(),
          userId: userId,
        );
        created.load();
        return created;
      },
      child: const _PlatformUserDetailView(),
    );
  }
}

class _PlatformUserDetailView extends StatelessWidget {
  const _PlatformUserDetailView();

  void _showActionsBottomSheet(BuildContext context) {
    final colors = context.vColors;
    final cubit = context.read<PlatformUserDetailCubit>();
    final state = cubit.state;

    showVBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const VText(
              'Thao tác người dùng',
              variant: VTextVariant.headingH3,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const VGap.md(),
            if (state.showActivationInvite) ...[
              PlatformUserActionCard(
                icon: VIcons.send,
                title: 'Gửi lại email kích hoạt',
                subtitle: 'Vô hiệu hóa liên kết cũ và gửi email mới',
                onTap: () {
                  Navigator.pop(context);
                  _confirm(
                    context: context,
                    title: 'Gửi lại email kích hoạt?',
                    titleColor: colors.textPrimary,
                    description:
                        'Liên kết kích hoạt cũ sẽ hết hiệu lực. Email mới được gửi tới người dùng.',
                    actionLabel: 'Gửi email',
                    actionVariant: VButtonVariant.primary,
                    onConfirm: (_) => cubit.sendActivationInvitation(),
                    successFallback: 'Đã gửi lại email kích hoạt thành công.',
                  );
                },
              ),
              const VGap.md(),
            ],
            if (state.showPasswordReset) ...[
              PlatformUserActionCard(
                icon: VIcons.lock,
                title: 'Đặt lại mật khẩu',
                subtitle: 'Gửi yêu cầu đặt lại mật khẩu cho người dùng',
                onTap: () {
                  Navigator.pop(context);
                  _confirm(
                    context: context,
                    title: 'Gửi yêu cầu đặt lại mật khẩu?',
                    titleColor: colors.textPrimary,
                    description:
                        'Hệ thống gửi hướng dẫn đặt lại mật khẩu. Admin không nhận mật khẩu mới.',
                    actionLabel: 'Gửi yêu cầu',
                    actionVariant: VButtonVariant.primary,
                    onConfirm: (_) => cubit.requestPasswordReset(),
                    successFallback: 'Đã gửi yêu cầu đặt lại mật khẩu.',
                  );
                },
              ),
              const VGap.md(),
            ],
            if (state.showSuspend) ...[
              PlatformUserActionCard(
                icon: VIcons.pause,
                title: 'Tạm ngừng người dùng',
                subtitle: state.user?.status == PlatformUserStatus.pendingActivation
                    ? 'Chặn kích hoạt và đăng nhập'
                    : 'Chặn đăng nhập trên toàn nền tảng',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _confirm(
                    context: context,
                    title: 'Tạm ngừng người dùng?',
                    titleColor: colors.danger,
                    description:
                        'Người dùng sẽ không thể đăng nhập hoặc truy cập tổ chức. Dữ liệu vẫn được giữ lại.',
                    actionLabel: 'Tạm ngừng',
                    actionVariant: VButtonVariant.secondary,
                    actionTone: VComponentTone.danger,
                    requireReason: true,
                    onConfirm: (reason) => cubit.suspend(reason: reason),
                    successFallback: 'Đã tạm ngừng tài khoản thành công.',
                  );
                },
              ),
              const VGap.md(),
            ],
            if (state.showRestore) ...[
              PlatformUserActionCard(
                icon: VIcons.person,
                title: 'Khôi phục người dùng',
                subtitle: 'Cho phép đăng nhập lại',
                onTap: () {
                  Navigator.pop(context);
                  _confirm(
                    context: context,
                    title: 'Khôi phục người dùng?',
                    titleColor: colors.textPrimary,
                    description: 'Người dùng có thể đăng nhập lại theo quyền hiện hành.',
                    actionLabel: 'Khôi phục',
                    actionVariant: VButtonVariant.primary,
                    onConfirm: (_) => cubit.restore(),
                    successFallback: 'Đã khôi phục tài khoản thành công.',
                  );
                },
              ),
              const VGap.md(),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirm({
    required BuildContext context,
    required String title,
    required Color titleColor,
    required String description,
    required String actionLabel,
    required VButtonVariant actionVariant,
    VComponentTone? actionTone,
    required Future<bool> Function(String reason) onConfirm,
    required String successFallback,
    bool requireReason = false,
  }) async {
    final cubit = context.read<PlatformUserDetailCubit>();
    await showPlatformUserConfirmSheet(
      context: context,
      title: title,
      titleColor: titleColor,
      description: description,
      actionLabel: actionLabel,
      actionVariant: actionVariant,
      actionTone: actionTone,
      requireReason: requireReason,
      onConfirm: onConfirm,
    );
    if (!context.mounted) return;
    final message = cubit.state.successMessage;
    if (message != null) {
      VToast.show(
        context,
        title: 'Thành công',
        message: message.isEmpty ? successFallback : message,
        type: VToastType.success,
      );
      cubit.clearFeedback();
      return;
    }
    final failure = cubit.state.failure;
    if (failure != null) {
      final isStepUp = failure.code == IamBlockedCodes.stepUpAuthRequired;
      VToast.show(
        context,
        title: isStepUp ? 'Cần xác thực bổ sung' : 'Không hoàn tất',
        message: failure.message,
        type: VToastType.danger,
      );
      cubit.clearFeedback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocBuilder<PlatformUserDetailCubit, PlatformUserDetailState>(
      builder: (context, state) {
        if (state.status == IamLoadStatus.loading || state.status == IamLoadStatus.initial) {
          return Scaffold(
            appBar: VAppBar(title: 'Chi tiết người dùng', showBackButton: true),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == IamLoadStatus.unauthorized) {
          return Scaffold(
            appBar: VAppBar(title: 'Chi tiết người dùng', showBackButton: true),
            body: Center(
              child: VText(
                state.failure?.message ?? 'Bạn không có quyền xem.',
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
              ),
            ),
          );
        }

        if (state.status == IamLoadStatus.empty || state.user == null) {
          return Scaffold(
            appBar: VAppBar(title: 'Chi tiết người dùng', showBackButton: true),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VText(
                    state.failure?.code == IamBlockedCodes.resourceNotFound
                        ? 'Không tìm thấy người dùng này.'
                        : (state.failure?.message ?? 'Không tải được chi tiết.'),
                    variant: VTextVariant.bodyDefault,
                    color: colors.textSecondary,
                  ),
                  if (state.status == IamLoadStatus.failure) ...[
                    const VGap.md(),
                    VButton(
                      label: 'Thử lại',
                      onPressed: () => context.read<PlatformUserDetailCubit>().load(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        if (state.status == IamLoadStatus.failure) {
          return Scaffold(
            appBar: VAppBar(title: 'Chi tiết người dùng', showBackButton: true),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VText(
                    state.failure?.message ?? 'Không tải được chi tiết.',
                    variant: VTextVariant.bodyDefault,
                    color: colors.textSecondary,
                  ),
                  const VGap.md(),
                  VButton(
                    label: 'Thử lại',
                    onPressed: () => context.read<PlatformUserDetailCubit>().load(),
                  ),
                ],
              ),
            ),
          );
        }

        final user = state.user!;
        final displayName = user.fullName.trim();

        final badgeTone = user.status == PlatformUserStatus.active
            ? VComponentTone.success
            : user.status == PlatformUserStatus.pendingActivation
            ? VComponentTone.warning
            : VComponentTone.danger;

        final badgeLabel = user.status == PlatformUserStatus.active
            ? 'Đang hoạt động'
            : user.status == PlatformUserStatus.pendingActivation
            ? 'Chờ kích hoạt'
            : 'Đã tạm ngừng';

        final canAct =
            state.showActivationInvite ||
            state.showPasswordReset ||
            state.showSuspend ||
            state.showRestore;

        return Scaffold(
          backgroundColor: colors.background,
          appBar: VAppBar(
            title: 'Chi tiết người dùng',
            showBackButton: true,
            actions: [
              if (canAct)
                IconButton(
                  icon: const VIcon(icon: VIcons.moreHoriz),
                  onPressed: () => _showActionsBottomSheet(context),
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(VSpacing.screenMobile),
                  children: [
                    VCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VBadge(
                            label: badgeLabel,
                            tone: badgeTone,
                            variant: VBadgeVariant.soft,
                            isSmall: true,
                          ),
                          const VGap.md(),
                          VCard(
                            onTap: () {},
                            child: Row(
                              children: [
                                VIconBox(
                                  icon: VIcons.person,
                                  size: 44,
                                  backgroundColor: colors.surfaceAlt,
                                  iconColor: colors.textSecondary,
                                  isCircular: true,
                                ),
                                const VGap.horizontalMd(),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      VText(
                                        displayName.isEmpty ? 'Chưa đặt tên' : displayName,
                                        variant: VTextVariant.headingH4,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const VGap.xs(),
                                      VText(
                                        'Tài khoản nền tảng',
                                        variant: VTextVariant.bodySmall,
                                        color: colors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                                VIcon(
                                  icon: VIcons.chevronRight,
                                  color: colors.textMuted,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VGap.md(),
                    PlatformUserDetailInfoCard(user: user),
                    const VGap.md(),
                    PlatformUserStatusAlert(status: user.status),
                    if (user.status != PlatformUserStatus.active) const VGap.md(),
                    PlatformUserMembershipList(memberships: user.memberships),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(
                    top: BorderSide(color: colors.borderDefault),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.screenMobile,
                      vertical: VSpacing.space3,
                    ),
                    child: VButton(
                      label: 'Thao tác',
                      fullWidth: true,
                      trailingIcon: const VIcon(
                        icon: VIcons.chevronUp,
                        color: Colors.white,
                        size: 16,
                      ),
                      onPressed: () => _showActionsBottomSheet(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
