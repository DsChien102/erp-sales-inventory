import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:admin/features/iam/presentation.dart';

void main() {
  testWidgets(
    'renders forensic IDs separately and keeps changes beside actor warning',
    (tester) async {
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText = (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final log = _log(
        correlationId: 'register-from-invitation-f8c17e2c-c550-42c8-934d-8154a92a3973',
        actorId: 'actor-uuid',
        actorType: 'service_account',
        actorRoleCode: 'tenant_owner',
        subjectName: 'Không còn thông tin đối tượng',
        subjectType: 'tenant',
        subjectId: 'subject-uuid',
        subjectCode: 'TEN-001',
        subjectDisplayOrigin: TenantAuditDisplayOrigin.unavailable,
        isActorUnavailable: true,
        changes: const [
          AuditLogChangeRowUiModel(
            fieldKey: 'display_name',
            fieldLabel: 'Tên hiển thị',
            beforeValue: 'Tên cũ',
            afterValue: 'Tên mới',
            isChanged: true,
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp(home: AuditLogDetailBody(log: log)));
      await tester.pumpAndSettle();

      expect(find.text('Không còn thông tin người thực hiện'), findsWidgets);
      expect(find.text('Loại chủ thể'), findsOneWidget);
      expect(find.text('Chủ sở hữu'), findsOneWidget);
      expect(find.text('Không còn thông tin đối tượng'), findsOneWidget);
      expect(find.text('TEN-001'), findsOneWidget);
      expect(find.text('Trước: Tên cũ'), findsOneWidget);
      expect(find.text('Sau: Tên mới'), findsOneWidget);
      expect(find.text('register-fro…a92a3973'), findsOneWidget);

      final trackingCopy = find.byTooltip('Sao chép mã theo dõi');
      await tester.ensureVisible(trackingCopy);
      await tester.tap(trackingCopy);
      await tester.pump();
      expect(
        copiedText,
        'register-from-invitation-f8c17e2c-c550-42c8-934d-8154a92a3973',
      );
    },
  );

  testWidgets('renders independent redaction cells and never raw hidden value', (
    tester,
  ) async {
    final log = _log(
      beforeRedacted: true,
      changes: const [
        AuditLogChangeRowUiModel(
          fieldKey: 'display_name',
          fieldLabel: 'Tên hiển thị',
          beforeValue: '[Đã che theo chính sách]',
          afterValue: 'Tên hiển thị mới',
          isChanged: true,
        ),
        AuditLogChangeRowUiModel(
          fieldKey: 'phone_number',
          fieldLabel: 'Số điện thoại',
          beforeValue: '[Đã che theo chính sách]',
          afterValue: '0909000000',
          isChanged: true,
        ),
      ],
      beforeState: 'RAW-BEFORE-SHOULD-NOT-RENDER',
    );

    await tester.pumpWidget(MaterialApp(home: AuditLogDetailBody(log: log)));
    await tester.pumpAndSettle();

    expect(
      find.text('Trước: [Đã che theo chính sách]'),
      findsNWidgets(2),
    );
    expect(find.text('Sau: Tên hiển thị mới'), findsOneWidget);
    expect(find.text('Sau: 0909000000'), findsOneWidget);
    expect(find.textContaining('RAW-BEFORE-SHOULD-NOT-RENDER'), findsNothing);
  });
}

AuditLogItemUiModel _log({
  String correlationId = 'tracking-1',
  String actorId = '',
  String actorType = '',
  String actorRoleCode = '',
  String subjectName = 'Phòng khám',
  String subjectType = 'tenant',
  String subjectId = '',
  String subjectCode = '',
  TenantAuditDisplayOrigin subjectDisplayOrigin = TenantAuditDisplayOrigin.snapshot,
  bool isActorUnavailable = false,
  bool beforeRedacted = false,
  String beforeState = '',
  List<AuditLogChangeRowUiModel> changes = const [],
}) {
  return AuditLogItemUiModel(
    id: 'audit-1',
    title: 'Hoạt động quản trị',
    actionCode: 'iam.unknown.event',
    status: AuditLogStatus.success,
    statusLabel: 'Thành công',
    actorName: isActorUnavailable ? 'Không còn thông tin người thực hiện' : 'Nguyễn Văn A',
    actorRole: 'Chủ sở hữu',
    actorId: actorId,
    actorType: actorType,
    actorRoleCode: actorRoleCode,
    targetOrg: subjectName,
    targetOrgCode: subjectCode,
    subjectName: subjectName,
    subjectType: subjectType,
    subjectId: subjectId,
    subjectCode: subjectCode,
    subjectDisplayOrigin: subjectDisplayOrigin,
    timestamp: DateTime(2026, 8, 20),
    sourceApp: 'iam',
    correlationId: correlationId,
    beforeState: beforeState,
    afterState: '',
    icon: VIcons.history,
    isActorUnavailable: isActorUnavailable,
    beforeRedacted: beforeRedacted,
    changes: changes,
  );
}
