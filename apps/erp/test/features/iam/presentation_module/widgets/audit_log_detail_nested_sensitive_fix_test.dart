import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/features/iam/data/models/tenant_audit_log.dart';

import 'package:erp/features/iam/presentation.dart';

void main() {
  testWidgets('detail never renders raw nested sensitive values from either side', (
    tester,
  ) async {
    final detail = TenantAuditLogDetailDto(
      auditLogId: 'audit-sensitive',
      tenantId: 'tenant-1',
      eventCode: IamAuditEvents.tenantProfileUpdated,
      result: TenantAuditLogResult.success,
      occurredAt: DateTime.utc(2026, 8, 20),
      source: 'iam',
      trackingId: 'tracking-sensitive',
      actorUnavailable: false,
      beforeRedacted: false,
      afterRedacted: false,
      actor: const TenantAuditActorDto(),
      subject: const TenantAuditSubjectDto(),
      beforeState: const {
        'metadata': [
          {
            'session_nonce': 'RAW-BEFORE-NONCE',
            'encrypted_ciphertext': 'RAW-BEFORE-CIPHERTEXT',
            'safe_label': 'Visible before',
          },
        ],
      },
      afterState: const {
        'metadata': [
          {
            'session_cookie': 'RAW-AFTER-SESSION',
            'private_key': 'RAW-AFTER-PRIVATE-KEY',
            'safe_label': 'Visible after',
          },
        ],
      },
    );
    final log = TenantAuditUiMapper.fromDetail(detail);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AuditDetailNarrow(log: log))));
    await tester.pumpAndSettle();

    expect(find.textContaining('RAW-BEFORE-NONCE'), findsNothing);
    expect(find.textContaining('RAW-BEFORE-CIPHERTEXT'), findsNothing);
    expect(find.textContaining('RAW-AFTER-SESSION'), findsNothing);
    expect(find.textContaining('RAW-AFTER-PRIVATE-KEY'), findsNothing);
    expect(find.textContaining('[Đã che theo chính sách]'), findsNWidgets(2));
    expect(find.textContaining('Visible before'), findsOneWidget);
    expect(find.textContaining('Visible after'), findsOneWidget);
  });
}
