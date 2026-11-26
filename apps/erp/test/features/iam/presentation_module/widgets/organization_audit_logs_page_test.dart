import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/iam/data/audit_log_repository.dart';
import 'package:erp/features/iam/data/models/tenant_audit_log.dart';
import 'package:supabase/supabase.dart';
import '../../support/fake_iam_backend.dart';
import 'package:erp/features/iam/presentation.dart';

void main() {
  testWidgets('loads audit logs and renders total count in subtitle', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationAuditLogsPage(
          auditLogs: FakeAuditLogRepository(FakeIamBackend(scenario: FakeIamScenario.tenantAuditSearchOk)),
          clockLocal: () => DateTime(2026, 7, 31),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lịch sử quản trị'), findsOneWidget);
    expect(find.textContaining('hoạt động trong 30 ngày'), findsOneWidget);
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Thành viên'), findsOneWidget);
    expect(find.text('Vai trò'), findsOneWidget);
    expect(find.text('Tổ chức'), findsOneWidget);
  });

  testWidgets('category chip taps update filtered query', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final recording = FakeIamBackend(scenario: FakeIamScenario.tenantAuditSearchOk);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationAuditLogsPage(
          auditLogs: FakeAuditLogRepository(recording),
          clockLocal: () => DateTime(2026, 7, 31),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thành viên'));
    await tester.pumpAndSettle();

    final queries = recording.queriesOf<SearchTenantAuditLogsQuery>().toList();
    expect(queries.length, greaterThan(1));
    expect(queries.last.eventCategory, 'member');
  });

  testWidgets('search text field triggers debounced search with query', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final recording = FakeIamBackend(scenario: FakeIamScenario.tenantAuditSearchOk);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationAuditLogsPage(
          auditLogs: FakeAuditLogRepository(recording),
          clockLocal: () => DateTime(2026, 7, 31),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(VSearchBar), 'Bác sĩ A');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    final queries = recording.queriesOf<SearchTenantAuditLogsQuery>().toList();
    expect(queries.last.query, 'Bác sĩ A');
  });

  testWidgets('actor unavailable detail shows generic actor message', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AuditLogDetailPage(
          auditLogId: 'AUD-T-001',
          auditLogs: FakeAuditLogRepository(FakeIamBackend(
            scenario: FakeIamScenario.tenantAuditActorUnavailable,
          )),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Không còn thông tin người thực hiện'),
      findsWidgets,
    );
  });

  testWidgets('detail renders change diff rows correctly', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AuditLogDetailPage(
          auditLogId: 'AUD-T-001',
          auditLogs: FakeAuditLogRepository(FakeIamBackend(scenario: FakeIamScenario.tenantAuditDetailOk)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tên hiển thị'), findsOneWidget);
    expect(find.text('Trước: Old'), findsOneWidget);
    expect(find.text('Sau: New'), findsOneWidget);
  });

  testWidgets('cross-tenant detail shows generic not found', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AuditLogDetailPage(
          auditLogId: 'AUD-T-999',
          auditLogs: FakeAuditLogRepository(FakeIamBackend(
            scenario: FakeIamScenario.tenantAuditCrossTenant,
          )),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy hoạt động'), findsOneWidget);
  });

  testWidgets('has back button and filter tooltip updates to (đang áp dụng) when active', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final recording = FakeIamBackend(scenario: FakeIamScenario.tenantAuditSearchOk);

    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        theme: VTheme.lightTheme,
        home: const Scaffold(body: Text('Previous Page')),
      ),
    );
    navKey.currentState!.push(
      MaterialPageRoute(
        builder: (_) => OrganizationAuditLogsPage(
          auditLogs: FakeAuditLogRepository(recording),
          clockLocal: () => DateTime(2026, 7, 31),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Quay lại'), findsOneWidget);
    expect(find.byTooltip('Bộ lọc'), findsOneWidget);
    expect(find.byTooltip('Bộ lọc (đang áp dụng)'), findsNothing);

    // Open filter sheet
    await tester.tap(find.byTooltip('Bộ lọc'));
    await tester.pumpAndSettle();

    // Select "Lỗi" status and apply
    await tester.tap(find.text('Lỗi'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(VButton, 'Áp dụng'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Bộ lọc'), findsNothing);
    expect(find.byTooltip('Bộ lọc (đang áp dụng)'), findsOneWidget);
  });

  testWidgets('accessibility guidelines: tap target size and labeled tap target', (tester) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final recording = FakeIamBackend(scenario: FakeIamScenario.tenantAuditSearchOk);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationAuditLogsPage(
          auditLogs: FakeAuditLogRepository(recording),
          clockLocal: () => DateTime(2026, 7, 31),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    handle.dispose();
  });

  testWidgets('390 groups by Vietnam day with times', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _ScriptedAuditRepo(
      onSearch: (_) async => TenantAuditLogPage(
        totalCount: 1,
        items: [
          TenantAuditLogSummaryDto(
            auditLogId: 'a1',
            eventCode: IamAuditEvents.tenantProfileUpdated,
            result: TenantAuditLogResult.success,
            // 2026-11-21T17:30Z == 22/11/2026 00:30 VN
            occurredAt: DateTime.utc(2026, 11, 21, 17, 30),
            source: 'tenant_app',
            trackingId: 'req-1',
            actor: const TenantAuditActorDto(displayName: 'Lan', roleLabel: 'Chủ cửa hàng'),
            subject: const TenantAuditSubjectDto(type: 'tenant', displayName: 'An Phát'),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationAuditLogsPage(
          auditLogs: repo,
          clockLocal: () => DateTime.utc(2026, 11, 22, 3),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('22/11/2026'), findsOneWidget);
    expect(find.text('00:30'), findsOneWidget);
  });

  testWidgets('390 and 1280 show Bị chặn / Lỗi badges only', (tester) async {
    final repo = _ScriptedAuditRepo(
      onSearch: (_) async => TenantAuditLogPage(
        totalCount: 3,
        items: [
          TenantAuditLogSummaryDto(
            auditLogId: 'a-ok',
            eventCode: IamAuditEvents.tenantProfileUpdated,
            result: TenantAuditLogResult.success,
            occurredAt: DateTime.utc(2026, 11, 22, 3),
            source: 'tenant_app',
            trackingId: 'r1',
            actor: const TenantAuditActorDto(displayName: 'Lan'),
            subject: const TenantAuditSubjectDto(type: 'tenant', displayName: 'An Phát'),
          ),
          TenantAuditLogSummaryDto(
            auditLogId: 'a-blocked',
            eventCode: IamAuditEvents.membershipRemoved,
            result: TenantAuditLogResult.blocked,
            occurredAt: DateTime.utc(2026, 11, 22, 2),
            source: 'tenant_app',
            trackingId: 'r2',
            actor: const TenantAuditActorDto(displayName: 'Lan'),
            subject: const TenantAuditSubjectDto(type: 'membership', displayName: 'Minh'),
          ),
          TenantAuditLogSummaryDto(
            auditLogId: 'a-err',
            eventCode: IamAuditEvents.invitationRevoked,
            result: TenantAuditLogResult.error,
            occurredAt: DateTime.utc(2026, 11, 22, 1),
            source: 'tenant_app',
            trackingId: 'r3',
            actor: const TenantAuditActorDto(displayName: 'Lan'),
            subject: const TenantAuditSubjectDto(type: 'invitation', displayName: 'vy@a.vn'),
          ),
        ],
      ),
    );

    for (final size in const [Size(390, 844), Size(1280, 800)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: VTheme.lightTheme,
          home: OrganizationAuditLogsPage(
            auditLogs: repo,
            clockLocal: () => DateTime.utc(2026, 11, 22, 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thành công'), findsNothing);
      expect(find.text('Bị chặn'), findsOneWidget);
      expect(find.text('Lỗi'), findsOneWidget);

      // README 50: dòng đối tượng là "<loại>: <tên>", không phải "Loại đối tượng".
      expect(find.textContaining('Loại đối tượng'), findsNothing);
      if (size.width < 840) {
        expect(find.text('Thành viên: Minh'), findsOneWidget);
        expect(find.text('Tổ chức: An Phát'), findsOneWidget);
      } else {
        expect(find.text('Thành viên'), findsWidgets);
        expect(find.text('Minh'), findsOneWidget);
      }
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('subtitle reads the selected range', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final recording = FakeIamBackend(scenario: FakeIamScenario.tenantAuditSearchOk);
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationAuditLogsPage(
          auditLogs: FakeAuditLogRepository(recording),
          clockLocal: () => DateTime.utc(2026, 7, 31, 3),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bộ lọc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('24 giờ'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(VButton, 'Áp dụng'));
    await tester.pumpAndSettle();

    expect(find.textContaining('hoạt động trong 24 giờ'), findsOneWidget);
  });

  testWidgets('reopening the sheet shows the applied range', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final recording = FakeIamBackend(scenario: FakeIamScenario.tenantAuditSearchOk);
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationAuditLogsPage(
          auditLogs: FakeAuditLogRepository(recording),
          clockLocal: () => DateTime.utc(2026, 7, 31, 3),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bộ lọc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 ngày'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(VButton, 'Áp dụng'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bộ lọc (đang áp dụng)'));
    await tester.pumpAndSettle();

    final sheet = tester.widget<AuditLogFilterBottomSheet>(
      find.byType(AuditLogFilterBottomSheet),
    );
    expect(sheet.initialCriteria.range, TenantAuditRange.d7);
  });

  testWidgets('range with no results offers Xóa bộ lọc, which also cancels typing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var call = 0;
    final repo = _ScriptedAuditRepo(
      onSearch: (_) async {
        call += 1;
        if (call == 1) {
          return TenantAuditLogPage(
            totalCount: 1,
            items: [
              TenantAuditLogSummaryDto(
                auditLogId: 'a1',
                eventCode: IamAuditEvents.tenantProfileUpdated,
                result: TenantAuditLogResult.success,
                occurredAt: DateTime.utc(2026, 11, 22, 3),
                source: 'tenant_app',
                trackingId: 'r1',
                actor: const TenantAuditActorDto(displayName: 'Lan'),
                subject: const TenantAuditSubjectDto(type: 'tenant', displayName: 'An Phát'),
              ),
            ],
          );
        }
        return const TenantAuditLogPage(totalCount: 0, items: []);
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationAuditLogsPage(
          auditLogs: repo,
          clockLocal: () => DateTime.utc(2026, 11, 22, 3),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bộ lọc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('24 giờ'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(VButton, 'Áp dụng'));
    await tester.pumpAndSettle();

    expect(find.text('Không có hoạt động phù hợp'), findsOneWidget);
    expect(find.text('Xóa bộ lọc'), findsOneWidget);

    await tester.enterText(find.byType(VSearchBar), 'abc');
    await tester.tap(find.text('Xóa bộ lọc'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    final searchField = tester.widget<VSearchBar>(find.byType(VSearchBar));
    expect(searchField.controller?.text, isEmpty);
  });

  testWidgets('load more failure shows a toast and keeps rows', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var call = 0;
    final repo = _ScriptedAuditRepo(
      onSearch: (cursor) async {
        call += 1;
        if (call > 1) {
          throw const AppException(
            IamBlockedCodes.systemError,
            serverMessage: 'Mất kết nối',
          );
        }
        return TenantAuditLogPage(
          totalCount: 2,
          nextCursor: 'next-1',
          items: [
            TenantAuditLogSummaryDto(
              auditLogId: 'a1',
              eventCode: IamAuditEvents.tenantProfileUpdated,
              result: TenantAuditLogResult.success,
              occurredAt: DateTime.utc(2026, 11, 22, 3),
              source: 'tenant_app',
              trackingId: 'r1',
              actor: const TenantAuditActorDto(displayName: 'Lan'),
              subject: const TenantAuditSubjectDto(type: 'tenant', displayName: 'An Phát'),
            ),
          ],
        );
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationAuditLogsPage(
          auditLogs: repo,
          clockLocal: () => DateTime.utc(2026, 11, 22, 3),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tải thêm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Cập nhật hồ sơ tổ chức'), findsOneWidget);
    expect(find.textContaining('Không tải thêm được'), findsOneWidget);
  });

  testWidgets('detail: network error is not reported as missing', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _ScriptedAuditRepo(
      onGetDetail: (_) async => throw const AppException(
        IamBlockedCodes.systemError,
        serverMessage: 'Lỗi mạng',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: AuditLogDetailPage(auditLogId: 'a1', auditLogs: repo),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tải được hoạt động'), findsOneWidget);
    expect(find.text('Không tìm thấy hoạt động'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('copy toast reads Đã sao chép mã theo dõi.', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: AuditLogDetailPage(
          auditLogId: 'AUD-T-001',
          auditLogs: FakeAuditLogRepository(
            FakeIamBackend(scenario: FakeIamScenario.tenantAuditDetailOk),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final copyBtn = find.byTooltip('Sao chép mã theo dõi');
    await tester.ensureVisible(copyBtn);
    await tester.pumpAndSettle();
    await tester.tap(copyBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Đã sao chép mã theo dõi.'), findsOneWidget);
  });
}

final class _ScriptedAuditRepo extends AuditLogRepository {
  _ScriptedAuditRepo({this.onSearch, this.onGetDetail})
    : super(
        rpc: SupabaseRpc(
          SupabaseClient(
            'http://127.0.0.1',
            'anon',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        ),
        tenantId: () async => 'tenant-1',
      );

  final Future<TenantAuditLogPage> Function(String? cursor)? onSearch;
  final Future<TenantAuditLogDetailDto> Function(String id)? onGetDetail;

  @override
  Future<TenantAuditLogPage> search({
    required DateTime from,
    required DateTime to,
    String? query,
    String? result,
    String? eventCategory,
    String? subjectType,
    List<String>? eventCodes,
    String? cursor,
    int limit = 20,
  }) => onSearch!(cursor);

  @override
  Future<TenantAuditLogDetailDto> getDetail(String auditLogId) =>
      onGetDetail!(auditLogId);
}
