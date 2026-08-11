import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/exception_mapper.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final result = await guard(
      () => getIt<IIamModule>().executeCommandAsync(SignOutCommand()),
    );

    if (!context.mounted) return;

    result.fold(
      (failure) {
        VToast.show(
          context,
          title: 'Đăng xuất thất bại',
          message: failure.message,
          type: VToastType.danger,
        );
      },
      (_) => context.go('/login'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.screenMobile,
            vertical: VSpacing.space4,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              VCard(
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        'Cài đặt thêm',
                        style: VTypography.headingH4.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const VGap.sm(),
                      VText(
                        'Các thiết lập mở rộng và thông tin tài khoản admin sẽ hiển thị ở đây.',
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const VGap.md(),
              VCard(
                onTap: () => _logout(context),
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: Row(
                    children: [
                      VIcon(
                        icon: VIcons.logout,
                        color: colors.danger,
                        size: 22,
                      ),
                      const VGap.horizontalMd(),
                      Expanded(
                        child: VText(
                          'Đăng xuất',
                          style: VTypography.bodyDefault.copyWith(
                            color: colors.danger,
                            fontWeight: FontWeight.w600,
                          ),
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
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
