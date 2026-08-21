import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_presentation/presentation.dart';

void main() {
  testWidgets('AuditLogFilterBottomSheet renders options and handles apply & reset', (
    WidgetTester tester,
  ) async {
    AuditLogFilterCriteria? appliedCriteria;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuditLogFilterBottomSheet(
            initialCriteria: const AuditLogFilterCriteria(),
            onApply: (criteria) {
              appliedCriteria = criteria;
            },
          ),
        ),
      ),
    );

    // Verify title & sections
    expect(find.text('Bộ lọc nhật ký nền tảng'), findsOneWidget);
    expect(find.text('Thời gian'), findsOneWidget);
    expect(find.text('Kết quả'), findsOneWidget);
    expect(find.text('Loại chủ thể'), findsOneWidget);

    // Verify chips
    expect(find.text('24 giờ'), findsOneWidget);
    expect(find.text('7 ngày'), findsOneWidget);
    expect(find.text('30 ngày'), findsOneWidget);
    expect(find.text('Người dùng'), findsOneWidget);
    expect(find.text('Hệ thống'), findsOneWidget);

    // Tap '7 ngày' chip
    await tester.tap(find.text('7 ngày'));
    await tester.pumpAndSettle();

    // Tap 'Áp dụng' button
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();

    expect(appliedCriteria?.timeRange, equals('7 ngày'));
  });
}
