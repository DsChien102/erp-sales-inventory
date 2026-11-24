import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/session/session_controller.dart';
import '../bloc/iam_feature_access_cubit.dart';
import '../bloc/iam_feature_access_state.dart';
import '../more_entries.dart';
import '../more_logout.dart';

class MorePage extends StatelessWidget {
  const MorePage({
    super.key,
    this.session,
    this.accessCubit,
    this.tenantBlocked = false,
  });

  final SessionController? session;
  final IamFeatureAccessCubit? accessCubit;
  final bool tenantBlocked;

  @override
  Widget build(BuildContext context) {
    if (accessCubit != null) {
      return BlocProvider.value(
        value: accessCubit!,
        child: _MoreView(
          onLogout: signOutAndGoToLogin,
          tenantBlocked: tenantBlocked,
        ),
      );
    }

    return BlocProvider(
      create: (ctx) {
        final resolvedSession = session ??
            (getIt.isRegistered<SessionController>()
                ? getIt<SessionController>()
                : ctx.read<SessionController>());
        final cubit = IamFeatureAccessCubit(
          session: resolvedSession,
        );
        // Tổ chức bị chặn: mọi RPC theo tổ chức đều bị từ chối → không gọi.
        if (!tenantBlocked) cubit.load();
        return cubit;
      },
      child: _MoreView(
        onLogout: signOutAndGoToLogin,
        tenantBlocked: tenantBlocked,
      ),
    );
  }
}

class _MoreView extends StatelessWidget {
  const _MoreView({
    required this.onLogout,
    required this.tenantBlocked,
  });

  final Future<void> Function(BuildContext context) onLogout;
  final bool tenantBlocked;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IamFeatureAccessCubit, IamFeatureAccessState>(
      builder: (context, access) {
        final blocked = tenantBlocked;
        final isOwner = access.canOpenIamHub;
        final menuItems = <Widget>[
          for (final entry in kMoreEntries)
            if (entry.isVisible(isOwner: isOwner, isBlocked: blocked))
              _MoreMenuItem(
                icon: entry.icon,
                title: entry.title,
                subtitle: entry.subtitle,
                enabled: entry.enabled && (!entry.needsActiveTenant || !blocked),
                isDestructive: entry.isDestructive,
                onTap: entry.isDestructive
                    ? () => onLogout(context)
                    : (entry.isInteractive(isBlocked: blocked)
                        ? () => context.push(entry.route!)
                        : null),
              ),
        ];

        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.screenMobile,
            vertical: VSpacing.space4,
          ),
          itemCount: menuItems.length,
          separatorBuilder: (context, index) => const SizedBox(height: VSpacing.space3),
          itemBuilder: (context, index) => menuItems[index],
        );
      },
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  const _MoreMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
    this.isDestructive = false,
  });

  final VIcons icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final isEnabled = enabled && onTap != null;
    final titleColor = isDestructive ? dynamicColors.danger : dynamicColors.textPrimary;
    final iconColor = isDestructive ? dynamicColors.danger : dynamicColors.primary;
    final iconBackgroundColor = isDestructive ? dynamicColors.dangerBg : dynamicColors.surfaceBrand;

    return Opacity(
      opacity: isEnabled ? 1 : 0.45,
      child: VCard(
        onTap: isEnabled ? onTap : null,
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space4,
          vertical: VSpacing.space3 + 2,
        ),
        child: Row(
          children: [
            VIconBox(
              icon: icon,
              size: 44,
              iconSize: 20,
              backgroundColor: iconBackgroundColor,
              iconColor: iconColor,
              borderRadius: VRadius.r12,
            ),
            const SizedBox(width: VSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  VText(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    variant: VTextVariant.headingH4,
                    color: titleColor,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const VGap.xs(),
                  VText(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    variant: VTextVariant.bodySmall,
                    color: dynamicColors.textSecondary,
                  ),
                ],
              ),
            ),
            if (isEnabled) ...[
              const SizedBox(width: VSpacing.space2),
              VIcon(
                icon: VIcons.chevronRight,
                color: dynamicColors.textSecondary,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
