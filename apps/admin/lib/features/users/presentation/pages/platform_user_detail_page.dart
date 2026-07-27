import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/presentation.dart';

import '../../../../core/di/injection.dart';
import '../bloc/platform_user_detail_cubit.dart';
import '../bloc/platform_user_detail_state.dart';

class PlatformUserDetailPage extends StatelessWidget {
  const PlatformUserDetailPage({
    super.key,
    required this.userId,
    this.iamModule,
  });

  final String userId;

  /// Optional override for widget / E2E tests. Defaults to GetIt [IIamModule].
  final IIamModule? iamModule;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = PlatformUserDetailCubit(
          iamModule: iamModule ?? getIt<IIamModule>(),
          userId: userId,
        );
        cubit.load();
        return cubit;
      },
      child: const _PlatformUserDetailView(),
    );
  }
}

class _PlatformUserDetailView extends StatelessWidget {
  const _PlatformUserDetailView();

  void _showActionsBottomSheet(
    BuildContext context,
    PlatformUserDetailDto user,
  ) {
    final colors = context.vColors;
    final cubit = context.read<PlatformUserDetailCubit>();

    showVBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VText(
              'Thao tác người dùng',
              variant: VTextVariant.headingH3,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const VGap.md(),
            if (user.status == PlatformUserStatus.active) ...[
              _ActionCard(
                icon: VIcons.pause,
                title: 'Tạm ngừng người dùng',
                subtitle: 'Chặn đăng nhập trên toàn nền tảng',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _showConfirmationSheet(
                    context: context,
                    title: 'Tạm ngừng người dùng?',
                    titleColor: colors.danger,
                    description:
                        'Người dùng sẽ không thể đăng nhập hoặc truy cập tổ chức. Dữ liệu vẫn được giữ lại.',
                    actionLabel: 'Tạm ngừng',
                    actionVariant: VButtonVariant.dangerOutline,
                    onConfirm: (reason) async {
                      final ok = await cubit.suspend(reason: reason);
                      if (context.mounted) {
                        Navigator.pop(context);
                        if (ok) {
                          VToast.show(
                            context,
                            title: 'Thành công',
                            message: 'Đã tạm ngừng tài khoản thành công.',
                            type: VToastType.success,
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ] else if (user.status == PlatformUserStatus.pendingActivation) ...[
              _ActionCard(
                icon: VIcons.mail,
                title: 'Gửi lại email kích hoạt',
                subtitle: 'Vô hiệu hóa liên kết cũ và gửi email mới',
                onTap: () {
                  Navigator.pop(context);
                  _showConfirmationSheet(
                    context: context,
                    title: 'Gửi lại email kích hoạt?',
                    titleColor: colors.textPrimary,
                    description:
                        'Liên kết kích hoạt cũ sẽ hết hiệu lực. Email mới được gửi tới người dùng.',
                    actionLabel: 'Gửi email',
                    actionVariant: VButtonVariant.primary,
                    onConfirm: (_) async {
                      final ok = await cubit.sendActivationInvitation();
                      if (context.mounted) {
                        Navigator.pop(context);
                        if (ok) {
                          VToast.show(
                            context,
                            title: 'Thành công',
                            message: 'Đã gửi lại email kích hoạt thành công.',
                            type: VToastType.success,
                          );
                        }
                      }
                    },
                  );
                },
              ),
              const VGap.md(),
              _ActionCard(
                icon: VIcons.pause,
                title: 'Tạm ngừng người dùng',
                subtitle: 'Chặn kích hoạt và đăng nhập',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _showConfirmationSheet(
                    context: context,
                    title: 'Tạm ngừng người dùng?',
                    titleColor: colors.danger,
                    description:
                        'Người dùng sẽ không thể đăng nhập hoặc truy cập tổ chức. Dữ liệu vẫn được giữ lại.',
                    actionLabel: 'Tạm ngừng',
                    actionVariant: VButtonVariant.dangerOutline,
                    onConfirm: (reason) async {
                      final ok = await cubit.suspend(reason: reason);
                      if (context.mounted) {
                        Navigator.pop(context);
                        if (ok) {
                          VToast.show(
                            context,
                            title: 'Thành công',
                            message: 'Đã tạm ngừng tài khoản thành công.',
                            type: VToastType.success,
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ] else if (user.status == PlatformUserStatus.suspended) ...[
              _ActionCard(
                icon: VIcons.person,
                title: 'Khôi phục người dùng',
                subtitle: 'Cho phép đăng nhập lại',
                onTap: () {
                  Navigator.pop(context);
                  _showConfirmationSheet(
                    context: context,
                    title: 'Khôi phục người dùng?',
                    titleColor: colors.textPrimary,
                    description:
                        'Người dùng có thể đăng nhập lại theo quyền hiện hành.',
                    actionLabel: 'Khôi phục',
                    actionVariant: VButtonVariant.primary,
                    onConfirm: (_) async {
                      final ok = await cubit.restore();
                      if (context.mounted) {
                        Navigator.pop(context);
                        if (ok) {
                          VToast.show(
                            context,
                            title: 'Thành công',
                            message: 'Đã khôi phục tài khoản thành công.',
                            type: VToastType.success,
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ],
            const VGap.md(),
          ],
        ),
      ),
    );
  }

  void _showConfirmationSheet({
    required BuildContext context,
    required String title,
    required Color titleColor,
    required String description,
    required String actionLabel,
    required VButtonVariant actionVariant,
    required Future<void> Function(String reason) onConfirm,
  }) {
    final reasonController = TextEditingController();

    showVBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VText(
              title,
              variant: VTextVariant.headingH3,
              color: titleColor,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const VGap.sm(),
            VText(
              description,
              variant: VTextVariant.bodyDefault,
              color: context.vColors.textSecondary,
            ),
            const VGap.md(),
            VTextFormField(
              label: 'Lý do (tuỳ chọn)',
              controller: reasonController,
              isRequired: false,
              maxLines: 1,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space3,
                vertical: VSpacing.space2,
              ),
              helperText: 'Lý do được lưu trong lịch sử quản trị.',
            ),
            const VGap.lg(),
            VButton(
              label: 'Quay lại',
              variant: VButtonVariant.outline,
              fullWidth: true,
              onPressed: () => Navigator.pop(context),
            ),
            const VGap.sm(),
            VButton(
              label: actionLabel,
              variant: actionVariant,
              fullWidth: true,
              onPressed: () => onConfirm(reasonController.text.trim()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocBuilder<PlatformUserDetailCubit, PlatformUserDetailState>(
      builder: (context, state) {
        if (state.status == PlatformUserDetailStatus.loading ||
            state.status == PlatformUserDetailStatus.initial) {
          return Scaffold(
            appBar: VAppBar(title: 'Chi tiết người dùng', showBackButton: true),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final user = state.user;
        if (user == null || state.status == PlatformUserDetailStatus.notFound) {
          return Scaffold(
            appBar: VAppBar(title: 'Chi tiết người dùng', showBackButton: true),
            body: Center(
              child: VText(
                'Không tìm thấy người dùng này.',
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
              ),
            ),
          );
        }

        final badgeStatus = user.status == PlatformUserStatus.active
            ? VBadgeStatus.success
            : user.status == PlatformUserStatus.pendingActivation
            ? VBadgeStatus.warning
            : VBadgeStatus.danger;

        final badgeLabel = user.status == PlatformUserStatus.active
            ? 'Đang hoạt động'
            : user.status == PlatformUserStatus.pendingActivation
            ? 'Chờ kích hoạt'
            : 'Đã tạm ngừng';

        return Scaffold(
          backgroundColor: colors.background,
          appBar: VAppBar(
            title: 'Chi tiết người dùng',
            showBackButton: true,
            actions: [
              IconButton(
                icon: const VIcon(icon: VIcons.moreHoriz),
                onPressed: () => _showActionsBottomSheet(context, user),
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
                            status: badgeStatus,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      VText(
                                        user.fullName,
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
                    if (user.status != PlatformUserStatus.active)
                      const VGap.md(),
                    PlatformUserMembershipList(memberships: user.memberships),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: colors.borderDefault)),
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
                      onPressed: () => _showActionsBottomSheet(context, user),
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final VIcons icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final cardBg = isDestructive ? colors.dangerBg : colors.surface;
    final cardBorder = isDestructive
        ? colors.danger.withValues(alpha: 0.18)
        : colors.borderDefault;
    final textColor = isDestructive ? colors.danger : colors.textPrimary;
    final subtitleColor = isDestructive
        ? colors.danger.withValues(alpha: 0.7)
        : colors.textSecondary;
    final iconColor = isDestructive ? colors.danger : colors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.r12),
        child: Ink(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(VRadius.r12),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space4,
              vertical: 14,
            ),
            child: Row(
              children: [
                VIcon(icon: icon, color: iconColor, size: 24),
                const VGap.horizontalMd(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        title,
                        variant: VTextVariant.bodyDefault,
                        color: textColor,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const VGap.xs(),
                      VText(
                        subtitle,
                        variant: VTextVariant.bodySmall,
                        color: subtitleColor,
                      ),
                    ],
                  ),
                ),
                VIcon(
                  icon: VIcons.chevronRight,
                  color: isDestructive ? colors.danger : colors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
