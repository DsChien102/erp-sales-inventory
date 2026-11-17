import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/session/session_state.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/legal_profile_home_banner.dart';
import 'widgets/metric_tile.dart';
import 'widgets/revenue_summary_card.dart';
import 'widgets/task_item.dart';

class HomeTabPage extends StatelessWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: BlocBuilder<SessionController, SessionState>(
        builder: (context, state) {
          return Column(
            children: [
              const DashboardHeader(),
              Expanded(child: _buildHomeBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHomeBody(BuildContext context, SessionState state) {
    final dynamicColors = context.vColors;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.screenMobile,
            VSpacing.space2,
            VSpacing.screenMobile,
            VSpacing.space4,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: VSpacing.space5),
              if (state.current?.isOwner == true && !state.legalProfileBannerDismissed)
                const LegalProfileHomeBanner(),
              VButton(
                label: 'Hỏi VET45',
                variant: VButtonVariant.secondary,
                fullWidth: true,
                onPressed: () => context.push('/ask'),
              ),
              const SizedBox(height: VSpacing.space4),
              const _SectionHeader(title: 'Tổng quan hôm nay'),
              const SizedBox(height: VSpacing.space2),
              const RevenueSummaryCard(),
              const SizedBox(height: VSpacing.space2),
              Row(
                children: [
                  Expanded(
                    child: MetricTile(
                      icon: Icons.receipt_long_outlined,
                      iconColor: dynamicColors.info,
                      iconBackgroundColor: dynamicColors.infoBg,
                      label: 'Đơn hôm nay',
                    ),
                  ),
                  const SizedBox(width: VSpacing.space2),
                  Expanded(
                    child: MetricTile(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: dynamicColors.warning,
                      iconBackgroundColor: dynamicColors.warningBg,
                      label: 'Phải thu',
                    ),
                  ),
                  const SizedBox(width: VSpacing.space2),
                  Expanded(
                    child: MetricTile(
                      icon: Icons.inventory_2_outlined,
                      iconColor: dynamicColors.danger,
                      iconBackgroundColor: dynamicColors.dangerBg,
                      label: 'Sắp hết',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VSpacing.space5),
              const _SectionHeader(title: 'Việc cần xử lý'),
              const SizedBox(height: VSpacing.space2),
              const TaskItem(
                icon: Icons.handshake_outlined,
                badgeStatus: VBadgeStatus.danger,
              ),
              const SizedBox(height: VSpacing.space2),
              const TaskItem(
                icon: Icons.inventory_2_outlined,
                badgeStatus: VBadgeStatus.warning,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  // ignore: unused_element_parameter
  const _SectionHeader({required this.title, this.trailingWidget});

  final String title;
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Row(
      children: [
        Expanded(
          child: VText(
            title,
            variant: VTextVariant.bodyDefault,
            color: dynamicColors.textPrimary,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        ?trailingWidget,
      ],
    );
  }
}
