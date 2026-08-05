import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_presentation/presentation.dart';

import '../../../../core/di/injection.dart';
import '../../../audit/presentation/mappers/platform_audit_ui_mapper.dart';

class AdminOverviewPage extends StatefulWidget {
  const AdminOverviewPage({
    super.key,
    this.iamModule,
    this.metrics,
    this.activities,
  });

  final IIamModule? iamModule;
  final AdminOverviewMetricsUiModel? metrics;
  final List<AdminActivityItemUiModel>? activities;

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> {
  static const _emptyMetrics = AdminOverviewMetricsUiModel(
    platformUsersCount: 0,
    platformUsersChange: '—',
    managedOrganizationsCount: 0,
    managedOrganizationsSubtext: '—',
    privilegedOperationsCount: 0,
    privilegedOperationsSubtext: '—',
    blockedOperationsCount: 0,
    blockedOperationsSubtext: '—',
  );

  AdminOverviewMetricsUiModel _metrics = _emptyMetrics;
  List<AdminActivityItemUiModel> _activities = const [];
  bool _isLoading = false;
  String? _errorMessage;

  bool get _usesInjectedData =>
      widget.metrics != null || widget.activities != null;

  @override
  void initState() {
    super.initState();
    if (_usesInjectedData) {
      _metrics = widget.metrics ?? _emptyMetrics;
      _activities = widget.activities ?? const [];
    } else {
      _loadOverview();
    }
  }

  Future<void> _loadOverview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final module = widget.iamModule ?? getIt<IIamModule>();
      final usersPage = await module
          .executeQueryAsync<CursorPageDto<PlatformUserSummaryDto>>(
            SearchPlatformUsersQuery(limit: 100),
          );
      final tenantsPage = await module
          .executeQueryAsync<CursorPageDto<PlatformTenantSummaryDto>>(
            SearchPlatformTenantsQuery(limit: 100),
          );
      final auditPage = await module
          .executeQueryAsync<CursorPageDto<PlatformAuditLogSummaryDto>>(
            SearchPlatformAuditLogsQuery(limit: 20),
          );

      if (!mounted) return;

      final blockedOrError = auditPage.items.where((log) {
        return log.status == PlatformAuditLogStatus.blocked ||
            log.status == PlatformAuditLogStatus.error;
      }).length;
      final provisioningTenants = tenantsPage.items.where((tenant) {
        return tenant.status == TenantLifecycleStatus.provisioning;
      }).length;
      final usersCreatedLast7Days = _countCreatedWithinDays(
        usersPage.items.map((user) => user.createdAt),
        days: 7,
      );

      setState(() {
        _metrics = AdminOverviewMetricsUiModel(
          platformUsersCount: usersPage.items.length,
          platformUsersChange: '+$usersCreatedLast7Days trong 7 ngày',
          managedOrganizationsCount: tenantsPage.items.length,
          managedOrganizationsSubtext: '$provisioningTenants đang thiết lập',
          privilegedOperationsCount: auditPage.items.length,
          privilegedOperationsSubtext: 'Trong 24 giờ',
          blockedOperationsCount: blockedOrError,
          blockedOperationsSubtext: blockedOrError == 0
              ? 'Không có cảnh báo'
              : 'Cần rà soát',
        );
        _activities = auditPage.items
            .take(5)
            .map(_activityFromAuditSummary)
            .toList(growable: false);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  static int _countCreatedWithinDays(
    Iterable<DateTime> createdAtValues, {
    required int days,
  }) {
    final cutoff = DateTime.now().toUtc().subtract(Duration(days: days));
    return createdAtValues.where((createdAt) {
      return !createdAt.toUtc().isBefore(cutoff);
    }).length;
  }

  static AdminActivityItemUiModel _activityFromAuditSummary(
    PlatformAuditLogSummaryDto log,
  ) {
    final mapped = PlatformAuditUiMapper.fromSummary(log);
    return AdminActivityItemUiModel(
      id: mapped.id,
      title: mapped.title,
      actorName: mapped.actorName,
      timestamp: mapped.timestamp,
      icon: switch (log.status) {
        PlatformAuditLogStatus.success => VIcons.edit,
        PlatformAuditLogStatus.blocked => VIcons.info,
        PlatformAuditLogStatus.error => VIcons.info,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final metrics = _usesInjectedData
        ? widget.metrics ?? _emptyMetrics
        : _metrics;
    final activities = _usesInjectedData
        ? widget.activities ?? const []
        : _activities;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          if (_isLoading) ...[
            const Center(child: CircularProgressIndicator()),
            const VGap.lg(),
          ] else if (_errorMessage != null) ...[
            VText(
              'Không tải được tổng quan quản trị',
              variant: VTextVariant.bodySmall,
              color: colors.danger,
            ),
            const VGap.lg(),
          ],
          VText(
            'Hoạt động đặc quyền gần đây',
            style: VTypography.bodyDefault.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const VGap.md(),
          if (activities.isEmpty)
            VText(
              'Chưa có hoạt động gần đây',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            )
          else
            for (int i = 0; i < activities.length; i++) ...[
              AdminActivityItemCard(activity: activities[i]),
              if (i < activities.length - 1) const VGap.sm(),
            ],
        ],
      ),
    );
  }
}
