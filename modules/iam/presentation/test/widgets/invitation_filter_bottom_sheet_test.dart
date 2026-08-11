import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_presentation/src/users/widgets/invitation_filter_bottom_sheet.dart';

void main() {
  testWidgets('InvitationFilterBottomSheet renders all sections and option chips',
      (WidgetTester tester) async {
    InvitationFilterCriteria? appliedCriteria;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InvitationFilterBottomSheet(
            initialCriteria: const InvitationFilterCriteria(),
            onApply: (criteria) {
              appliedCriteria = criteria;
            },
          ),
        ),
      ),
    );

    // Verify title & sections
    expect(find.text('Bộ lọc lời mời'), findsOneWidget);
    expect(find.text('Trạng thái'), findsOneWidget);
    expect(find.text('Kết quả gửi'), findsOneWidget);
    expect(find.text('Thời gian'), findsOneWidget);

    // Verify chip options
    expect(find.text('Đang chờ'), findsOneWidget);
    expect(find.text('Sắp hết hạn'), findsOneWidget);
    expect(find.text('Đã gửi'), findsOneWidget);
    expect(find.text('Gửi lỗi'), findsOneWidget);
    expect(find.text('Thu hồi'), findsOneWidget);
    expect(find.text('7 ngày'), findsOneWidget);
    expect(find.text('30 ngày'), findsOneWidget);
    expect(find.text('Tùy chọn'), findsOneWidget);

    // Tap 'Đang chờ', 'Đã gửi', '7 ngày'
    await tester.tap(find.text('Đang chờ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đã gửi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 ngày'));
    await tester.pumpAndSettle();

    // Tap Áp dụng
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();

    expect(appliedCriteria, isNotNull);
    expect(appliedCriteria!.status, 'Đang chờ');
    expect(appliedCriteria!.sendResult, 'Đã gửi');
    expect(appliedCriteria!.timeRange, '7 ngày');
  });

  testWidgets('InvitationFilterBottomSheet handles reset button',
      (WidgetTester tester) async {
    InvitationFilterCriteria? appliedCriteria;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InvitationFilterBottomSheet(
            initialCriteria: const InvitationFilterCriteria(
              status: 'Sắp hết hạn',
              sendResult: 'Gửi lỗi',
              timeRange: '30 ngày',
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

    expect(appliedCriteria, isNotNull);
    expect(appliedCriteria!.status, 'Tất cả');
    expect(appliedCriteria!.sendResult, 'Tất cả');
    expect(appliedCriteria!.timeRange, 'Tất cả');
  });
}
