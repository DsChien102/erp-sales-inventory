import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/overview/presentation/pages/admin_overview_page.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_presentation/testing.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  testWidgets('AdminOverviewPage renders metric cards and activity items', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminOverviewPage(
            metrics: FakeAdminOverviewData.metrics,
            activities: FakeAdminOverviewData.recentActivities,
          ),
        ),
      ),
    );

    // Verify 4 metric card labels and values
    expect(find.text('Người dùng nền tảng'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('+2 trong 7 ngày'), findsOneWidget);

    expect(find.text('Tổ chức đang quản lý'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('1 đang thiết lập'), findsOneWidget);

    expect(find.text('Thao tác đặc quyền'), findsOneWidget);
    expect(find.text('126'), findsOneWidget);
    expect(find.text('Trong 24 giờ'), findsOneWidget);

    expect(find.text('Thao tác bị chặn'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Cần rà soát'), findsOneWidget);

    // Verify activity section title and items
    expect(find.text('Hoạt động đặc quyền gần đây'), findsOneWidget);
    expect(find.text('Đã tạm ngừng tổ chức'), findsOneWidget);
    expect(find.text('Từ chối thao tác không đủ quyền'), findsOneWidget);
  });

  testWidgets(
    'AdminOverviewPage loads metrics and recent activity from IAM module',
    (WidgetTester tester) async {
      final module = _OverviewIamModule();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AdminOverviewPage(iamModule: module)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('2'), findsWidgets);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Cần rà soát'), findsOneWidget);
      expect(find.text('+0 trong 7 ngày'), findsOneWidget);
      expect(find.text('1 đang thiết lập'), findsOneWidget);
      expect(find.text('Trong 24 giờ'), findsOneWidget);
      expect(find.text('Đã tạm ngừng tổ chức'), findsOneWidget);
      expect(module.seenQueries, contains(SearchPlatformUsersQuery));
      expect(module.seenQueries, contains(SearchPlatformTenantsQuery));
      expect(module.seenQueries, contains(SearchPlatformAuditLogsQuery));
    },
  );
}

final class _OverviewIamModule implements IIamModule {
  final List<Type> seenQueries = [];

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('Unexpected command ${command.runtimeType}');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    seenQueries.add(query.runtimeType);

    if (query is SearchPlatformUsersQuery) {
      return CursorPageDto<PlatformUserSummaryDto>(
            items: [
              PlatformUserSummaryDto(
                userId: 'user-1',
                fullName: 'Lan',
                email: 'lan@example.com',
                status: PlatformUserStatus.active,
                createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
              ),
              PlatformUserSummaryDto(
                userId: 'user-2',
                fullName: 'Minh',
                email: 'minh@example.com',
                status: PlatformUserStatus.pendingActivation,
                createdAt: DateTime.parse('2026-01-02T00:00:00Z'),
              ),
            ],
          )
          as TResult;
    }

    if (query is SearchPlatformTenantsQuery) {
      return CursorPageDto<PlatformTenantSummaryDto>(
            items: [
              PlatformTenantSummaryDto(
                tenantId: 'tenant-1',
                name: 'One',
                code: 'TEN-1',
                status: TenantLifecycleStatus.active,
                createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
              ),
              PlatformTenantSummaryDto(
                tenantId: 'tenant-2',
                name: 'Two',
                code: 'TEN-2',
                status: TenantLifecycleStatus.provisioning,
                createdAt: DateTime.parse('2026-01-02T00:00:00Z'),
              ),
              PlatformTenantSummaryDto(
                tenantId: 'tenant-3',
                name: 'Three',
                code: 'TEN-3',
                status: TenantLifecycleStatus.suspended,
                createdAt: DateTime.parse('2026-01-03T00:00:00Z'),
              ),
            ],
          )
          as TResult;
    }

    if (query is SearchPlatformAuditLogsQuery) {
      return CursorPageDto<PlatformAuditLogSummaryDto>(
            items: [
              PlatformAuditLogSummaryDto(
                id: 'audit-1',
                title: 'Đã tạm ngừng tổ chức',
                actionCode: 'iam.tenant.suspended',
                status: PlatformAuditLogStatus.success,
                actorName: 'Admin',
                actorRole: 'Platform admin',
                targetOrgName: 'One',
                targetOrgCode: 'TEN-1',
                timestamp: DateTime.parse('2026-01-03T00:00:00Z'),
                sourceApp: 'admin',
              ),
              PlatformAuditLogSummaryDto(
                id: 'audit-2',
                title: 'Từ chối thao tác không đủ quyền',
                actionCode: 'iam.permission.denied',
                status: PlatformAuditLogStatus.blocked,
                actorName: 'Admin',
                actorRole: 'Platform admin',
                targetOrgName: 'Two',
                targetOrgCode: 'TEN-2',
                timestamp: DateTime.parse('2026-01-02T00:00:00Z'),
                sourceApp: 'admin',
              ),
              PlatformAuditLogSummaryDto(
                id: 'audit-3',
                title: 'Lỗi thao tác',
                actionCode: 'iam.operation.error',
                status: PlatformAuditLogStatus.error,
                actorName: 'System',
                actorRole: 'Hệ thống',
                targetOrgName: 'Three',
                targetOrgCode: 'TEN-3',
                timestamp: DateTime.parse('2026-01-01T00:00:00Z'),
                sourceApp: 'admin',
              ),
              PlatformAuditLogSummaryDto(
                id: 'audit-4',
                title: 'Làm mới chính sách quyền',
                actionCode: 'iam.policy.refreshed',
                status: PlatformAuditLogStatus.success,
                actorName: 'System',
                actorRole: 'Hệ thống',
                targetOrgName: 'Nền tảng',
                targetOrgCode: 'PLATFORM',
                timestamp: DateTime.parse('2026-01-01T01:00:00Z'),
                sourceApp: 'admin',
              ),
            ],
          )
          as TResult;
    }

    throw UnsupportedError('Unexpected query ${query.runtimeType}');
  }
}
