import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/iam/presentation.dart';

void main() {
  testWidgets('filter sheet has two groups; reset returns to 30 ngày and applies', (
    WidgetTester tester,
  ) async {
    AuditLogFilterCriteria? appliedCriteria;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuditLogFilterBottomSheet(
            initialCriteria: const AuditLogFilterCriteria(
              range: TenantAuditRange.h24,
              status: AuditLogStatus.blocked,
            ),
            onApply: (criteria) {
              appliedCriteria = criteria;
            },
          ),
        ),
      ),
    );

    // Two groups only (Q3)
    expect(find.text('Thời gian'), findsOneWidget);
    expect(find.text('Kết quả'), findsOneWidget);
    expect(find.text('Loại chủ thể'), findsNothing);
    expect(find.text('Người dùng'), findsNothing);
    expect(find.text('Hệ thống'), findsNothing);

    expect(find.text('24 giờ'), findsOneWidget);
    expect(find.text('7 ngày'), findsOneWidget);
    expect(find.text('30 ngày'), findsOneWidget);

    await tester.tap(find.text('7 ngày'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();

    expect(appliedCriteria?.range, equals(TenantAuditRange.d7));
    expect(appliedCriteria?.status, equals(AuditLogStatus.blocked));

    // Re-pump and test reset -> 30 ngày & status null (Q2)
    appliedCriteria = null;
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: Scaffold(
          body: AuditLogFilterBottomSheet(
            initialCriteria: const AuditLogFilterCriteria(
              range: TenantAuditRange.d7,
              status: AuditLogStatus.error,
            ),
            onApply: (criteria) {
              appliedCriteria = criteria;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Đặt lại'));
    await tester.pumpAndSettle();

    expect(appliedCriteria?.range, equals(TenantAuditRange.d30));
    expect(appliedCriteria?.status, isNull);
  });
}
