import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/iam/data/models/tenant_audit_log.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:erp/features/iam/presentation/audit_logs/widgets/detail_part.dart';

void main() {
  testWidgets('detail labels: Vai trò, Dữ liệu thay đổi, Mã nhật ký', (tester) async {
    final log = _sampleLog(changesCount: 1);

    for (final size in const [Size(390, 844), Size(1280, 800)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: size.width >= 840
                ? AuditDetailWide(log: log)
                : AuditDetailNarrow(log: log),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vai trò'), findsOneWidget);
      expect(find.text('Dữ liệu thay đổi'), findsOneWidget);
      expect(find.text('Mã nhật ký'), findsOneWidget);
      expect(find.text('Loại chủ thể'), findsNothing);
      expect(find.text('Audit ID'), findsNothing);

      // iPhone (proto traceRow): nhãn "Mã theo dõi" trên, mã dưới cùng lề trái; web một hàng.
      final label = tester.getTopLeft(find.text('Mã theo dõi'));
      final code = tester.getTopLeft(find.text(formatAuditTraceId(log.correlationId)));
      if (size.width < 840) {
        expect(code.dy, greaterThan(label.dy));
        expect(code.dx, label.dx);
      } else {
        expect(code.dx, greaterThan(label.dx));
      }
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('30 changes and missing actor do not overflow at 320 and 840', (tester) async {
    final log = _sampleLog(changesCount: 30, actorUnavailable: true);

    for (final size in const [Size(320, 844), Size(840, 800)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: size.width >= 840
                ? AuditDetailWide(log: log)
                : AuditDetailNarrow(log: log),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

AuditLogItemUiModel _sampleLog({
  required int changesCount,
  bool actorUnavailable = false,
}) {
  return AuditLogItemUiModel(
    id: 'a1',
    auditDisplayId: 'AUD-0001',
    title: 'Thay đổi vai trò thành viên',
    actionCode: 'iam.membership.role_changed',
    status: AuditLogStatus.success,
    statusLabel: 'Thành công',
    actorName: actorUnavailable
        ? 'Không còn thông tin người thực hiện'
        : 'Nguyễn Thị Lan',
    actorRole: actorUnavailable ? '—' : 'Chủ cửa hàng',
    targetOrg: 'Trần Văn Minh',
    targetOrgCode: 'M-1',
    timestamp: DateTime.utc(2026, 11, 22, 3, 21),
    sourceApp: 'Ứng dụng',
    correlationId: 'req_7f3a9c21e0b4d6a8b1e5f3c8d19f02',
    beforeState: '',
    afterState: '',
    icon: VIcons.people,
    category: 'role',
    eventCategory: TenantAuditEventCategory.role,
    targetSubjectLabel: 'Thành viên',
    targetDetailLabel: 'ID đối tượng',
    targetDetailValue: '5f1c2a9e…7b3d',
    subjectName: 'Trần Văn Minh',
    isActorUnavailable: actorUnavailable,
    changes: List.generate(
      changesCount,
      (i) => AuditLogChangeRowUiModel(
        fieldKey: 'field_$i',
        fieldLabel: 'Trường thông tin rất dài số ${i + 1}',
        beforeValue: 'Giá trị cũ $i',
        afterValue: 'Giá trị mới $i',
        isChanged: true,
      ),
    ),
  );
}
