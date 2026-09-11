import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/iam/presentation/users/widgets/member_filter_bottom_sheet.dart';

void main() {
  testWidgets('MemberFilterBottomSheet renders all sections and option chips',
      (WidgetTester tester) async {
    MemberFilterCriteria? appliedCriteria;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemberFilterBottomSheet(
            initialCriteria: const MemberFilterCriteria(),
            onApply: (criteria) {
              appliedCriteria = criteria;
            },
          ),
        ),
      ),
    );

    // Verify title & sections
    expect(find.text('Bộ lọc thành viên'), findsOneWidget);
    expect(find.text('Trạng thái'), findsOneWidget);
    expect(find.text('Vai trò'), findsOneWidget);
    expect(find.text('Sắp xếp'), findsOneWidget);

    // Verify chip options
    expect(find.text('Hoạt động'), findsOneWidget);
    expect(find.text('Tạm ngừng'), findsOneWidget);
    expect(find.text('Quản trị'), findsOneWidget);
    expect(find.text('Bán hàng'), findsOneWidget);
    expect(find.text('Kế toán'), findsOneWidget);
    expect(find.text('Tên A–Z'), findsOneWidget);
    expect(find.text('Tên Z–A'), findsOneWidget);

    // Tap 'Hoạt động', 'Bán hàng', 'Tên A–Z'
    await tester.tap(find.text('Hoạt động'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bán hàng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tên A–Z'));
    await tester.pumpAndSettle();

    // Tap Áp dụng
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();

    expect(appliedCriteria, isNotNull);
    expect(appliedCriteria!.status, 'Hoạt động');
    expect(appliedCriteria!.role, 'Bán hàng');
    expect(appliedCriteria!.sort, 'Tên A–Z');
  });

  testWidgets('MemberFilterBottomSheet handles reset button',
      (WidgetTester tester) async {
    MemberFilterCriteria? appliedCriteria;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemberFilterBottomSheet(
            initialCriteria: const MemberFilterCriteria(
              status: 'Hoạt động',
              role: 'Quản trị',
              sort: 'Tên A–Z',
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
    expect(appliedCriteria!.role, 'Tất cả');
    expect(appliedCriteria!.sort, 'Tất cả');
  });
}
