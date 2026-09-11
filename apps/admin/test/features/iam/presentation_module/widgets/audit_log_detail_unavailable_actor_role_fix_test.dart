import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:admin/features/iam/presentation.dart';

void main() {
  testWidgets('unavailable actor shows warning and copyable real ID with neutral role', (
    tester,
  ) async {
    final log = TenantAuditUiMapper.fromDetail(
      TenantAuditLogDetailDto(
        auditLogId: 'audit-unavailable',
        tenantId: 'tenant-1',
        eventCode: IamAuditEvents.tenantActivated,
        result: TenantAuditLogResult.success,
        occurredAt: DateTime.utc(2026, 8, 20),
        source: 'iam',
        trackingId: 'tracking-unavailable',
        actorUnavailable: true,
        beforeRedacted: false,
        afterRedacted: false,
        actor: const TenantAuditActorDto(
          userId: 'actor-real-id',
          displayOrigin: TenantAuditDisplayOrigin.unavailable,
        ),
        subject: const TenantAuditSubjectDto(),
      ),
    );

    await tester.pumpWidget(MaterialApp(home: AuditLogDetailBody(log: log)));
    await tester.pumpAndSettle();

    expect(find.text('Không còn thông tin người thực hiện'), findsWidgets);
    expect(find.text('Tài khoản đã ngừng'), findsNothing);
    expect(find.text('Loại chủ thể'), findsOneWidget);
    expect(find.text('—'), findsWidgets);
  });
}
