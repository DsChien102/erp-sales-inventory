import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_presentation/presentation.dart';

class AdminOverviewPage extends StatelessWidget {
  const AdminOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final metrics = AdminOverviewMockData.metrics;
    final activities = AdminOverviewMockData.recentActivities;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 2x2 Metric Cards Grid
          Row(
            children: [
              Expanded(
                child: AdminOverviewMetricCard(
                  label: 'Người dùng nền tảng',
                  value: '${metrics.platformUsersCount}',
                  subtext: metrics.platformUsersChange,
                ),
              ),
              const VGap.horizontalMd(),
              Expanded(
                child: AdminOverviewMetricCard(
                  label: 'Tổ chức đang quản lý',
                  value: '${metrics.managedOrganizationsCount}',
                  subtext: metrics.managedOrganizationsSubtext,
                ),
              ),
            ],
          ),
          const VGap.md(),
          Row(
            children: [
              Expanded(
                child: AdminOverviewMetricCard(
                  label: 'Thao tác đặc quyền',
                  value: '${metrics.privilegedOperationsCount}',
                  subtext: metrics.privilegedOperationsSubtext,
                ),
              ),
              const VGap.horizontalMd(),
              Expanded(
                child: AdminOverviewMetricCard(
                  label: 'Thao tác bị chặn',
                  value: '${metrics.blockedOperationsCount}',
                  subtext: metrics.blockedOperationsSubtext,
                ),
              ),
            ],
          ),
          const VGap.xl(),

          // Section Title: Hoạt động đặc quyền gần đây
          VText(
            'Hoạt động đặc quyền gần đây',
            style: VTypography.bodyDefault.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const VGap.md(),

          // List of Activity Item Cards
          for (int i = 0; i < activities.length; i++) ...[
            AdminActivityItemCard(activity: activities[i]),
            if (i < activities.length - 1) const VGap.sm(),
          ],
        ],
      ),
    );
  }
}
