import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/iam/iam_codes.dart';
import '../../support/fake_iam_backend.dart';
import 'package:erp/features/iam/presentation.dart';

void main() {
  testWidgets(
    'localized search sends only eventCodes while free text sends only query',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final recording = FakeIamBackend(scenario: FakeIamScenario.tenantAuditSearchOk);
      await tester.pumpWidget(
        MaterialApp(
          home: OrganizationAuditLogsPage(
            auditLogs: FakeAuditLogRepository(recording),
            clockLocal: () => DateTime(2026, 8, 20),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(VSearchBar), '  Tạm ngừng thành viên  ');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      var query = recording.queriesOf<SearchTenantAuditLogsQuery>().last;
      expect(query.query, isNull);
      expect(query.eventCodes, contains(IamAuditEvents.membershipDeactivated));

      await tester.enterText(find.byType(VSearchBar), 'Bác sĩ A');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      query = recording.queriesOf<SearchTenantAuditLogsQuery>().last;
      expect(query.query, 'Bác sĩ A');
      expect(query.eventCodes, isNull);
    },
  );
}
