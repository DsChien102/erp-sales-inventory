import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:erp/features/iam/presentation.dart';

void main() {
  testWidgets('AuditLogDetailBody renders change section with diff rows', (
    tester,
  ) async {
    final log = AuditLogItemUiModel(
      id: '#AUD-001',
      auditDisplayId: 'AUD-000982',
      title: 'Cập nhật hồ sơ tổ chức',
      actionCode: 'iam.tenant.profile_updated',
      status: AuditLogStatus.success,
      statusLabel: 'Thành công',
      actorName: 'Bác sĩ Lan Lê',
      actorRole: 'Bác sĩ thú y',
      targetOrg: 'Chi nhánh Quận 1',
      targetOrgCode: 'VET-Q1',
      targetSubjectLabel: 'Loại đối tượng',
      targetSubjectValue: 'Tổ chức',
      targetDetailLabel: 'Mã đối tượng',
      targetDetailValue: 'VET-Q1',
      timestamp: DateTime(2026, 8, 4, 3, 27),
      sourceApp: 'erp',
      correlationId: 'CORR-01',
      beforeState: '',
      afterState: '',
      icon: VIcons.apartment,
      changes: const [
        AuditLogChangeRowUiModel(
          fieldKey: 'status',
          fieldLabel: 'Trạng thái',
          beforeValue: 'Tạm ngừng',
          afterValue: 'Đang hoạt động',
          isChanged: true,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AuditLogDetailBody(log: log),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trạng thái'), findsOneWidget);
    expect(find.text('Trước: Tạm ngừng'), findsOneWidget);
    expect(find.text('Sau: Đang hoạt động'), findsOneWidget);
    expect(find.text('Bác sĩ Lan Lê'), findsOneWidget);
    expect(find.text('Bác sĩ thú y'), findsOneWidget);
    expect(find.text('Chi nhánh Quận 1'), findsOneWidget);
    expect(find.text('VET-Q1'), findsOneWidget);
    expect(find.text('AUD-000982'), findsOneWidget);
  });

  testWidgets('AuditLogDetailBody renders redacted message when redacted', (
    tester,
  ) async {
    final log = AuditLogItemUiModel(
      id: '#AUD-002',
      title: 'Đổi mật khẩu',
      actionCode: 'iam.account.password_reset_completed',
      status: AuditLogStatus.success,
      statusLabel: 'Thành công',
      actorName: 'Nguyen Van A',
      actorRole: 'Chủ sở hữu',
      targetOrg: 'Clinic 1',
      targetOrgCode: 'C-1',
      timestamp: DateTime(2026, 8, 4, 3, 27),
      sourceApp: 'iam',
      correlationId: 'CORR-02',
      beforeState: 'hashed_password',
      afterState: 'new_hashed_password',
      beforeRedacted: true,
      afterRedacted: true,
      icon: VIcons.lock,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AuditLogDetailBody(log: log),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dữ liệu nhạy cảm đã được che theo chính sách.'), findsOneWidget);
    expect(find.textContaining('[Đã che theo chính sách]'), findsNWidgets(2));
  });

  testWidgets('AuditLogDetailBody renders legacy indicator for current origin', (
    tester,
  ) async {
    final log = AuditLogItemUiModel(
      id: '#AUD-003',
      title: 'Tạm ngừng thành viên',
      actionCode: 'iam.membership.deactivated',
      status: AuditLogStatus.success,
      statusLabel: 'Thành công',
      actorName: 'Chủ sở hữu hiện tại',
      actorRole: 'Chủ phòng khám',
      actorDisplayOrigin: TenantAuditDisplayOrigin.current,
      targetOrg: 'Member 1',
      targetOrgCode: 'MEM-1',
      timestamp: DateTime(2026, 8, 4, 3, 27),
      sourceApp: 'erp',
      correlationId: 'CORR-03',
      beforeState: '',
      afterState: '',
      icon: VIcons.warning,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AuditLogDetailBody(log: log),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thông tin hiện tại'), findsOneWidget);
  });
}
