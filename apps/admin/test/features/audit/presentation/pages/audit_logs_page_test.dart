import 'package:admin/features/audit/presentation/pages/audit_logs_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    'wgt_e02_u10_fr01_01: AuditLogsPage renders search, chips, and log items',
    (tester) async {
      final module = FakeIamModule(scenario: FakeIamScenario.auditSearchOk);
      getIt
        ..registerSingleton(FakeExecutionContext())
        ..registerSingleton<IIamModule>(module);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AuditLogsPage(iamModule: module)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Thành công'), findsOneWidget);
      expect(find.text('Bị chặn'), findsOneWidget);
      expect(find.text('Lỗi'), findsOneWidget);

      expect(find.text('Đã tạm ngừng tổ chức'), findsOneWidget);
      expect(find.text('Từ chối thao tác không đủ quyền'), findsOneWidget);
      expect(find.text('Khởi tạo tổ chức chưa hoàn tất'), findsOneWidget);
      expect(find.text('Làm mới chính sách quyền'), findsOneWidget);
    },
  );

  testWidgets('AuditLogsPage filters logs when tapping status chips', (
    tester,
  ) async {
    final module = FakeIamModule(scenario: FakeIamScenario.auditSearchOk);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AuditLogsPage(iamModule: module)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bị chặn'));
    await tester.pumpAndSettle();

    expect(find.text('Từ chối thao tác không đủ quyền'), findsOneWidget);
    expect(find.text('Đã tạm ngừng tổ chức'), findsNothing);
  });
}
