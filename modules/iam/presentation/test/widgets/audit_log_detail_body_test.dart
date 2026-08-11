import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_presentation/presentation.dart';

void main() {
  testWidgets('AuditLogDetailBody renders change section according to design', (
    tester,
  ) async {
    final log = AuditLogItemUiModel(
      id: '#AUD-001',
      title: 'Khôi phục tổ chức',
      actionCode: 'iam.tenant.restored',
      status: AuditLogStatus.success,
      statusLabel: 'Thành công',
      actorName: 'Admin Test',
      actorRole: 'Nhân viên vận hành nền tảng',
      targetOrg: 'VietVet Trading',
      targetOrgCode: 'TEN-000095',
      targetSubjectLabel: 'Đối tượng',
      targetSubjectValue: 'VietVet Trading',
      targetDetailLabel: 'Mã',
      targetDetailValue: 'TEN-000095',
      timestamp: DateTime(2026, 8, 4, 3, 27),
      sourceApp: 'iam',
      correlationId: 'CORR-01',
      beforeState: 'Đang hoạt động',
      afterState: 'Đã tạm ngừng',
      beforeRedacted: true,
      afterRedacted: false,
      icon: VIcons.restore,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AuditLogDetailBody(log: log),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dữ liệu thay đổi'), findsOneWidget);
    expect(find.text('Trước'), findsOneWidget);
    expect(find.text('Sau'), findsOneWidget);
    expect(find.text('Đã tạm ngừng'), findsOneWidget);
    expect(
      find.text('Dữ liệu nhạy cảm đã được che theo chính sách.'),
      findsOneWidget,
    );
  });
}
