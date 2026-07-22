import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/overview/presentation/pages/admin_overview_page.dart';

void main() {
  testWidgets('AdminOverviewPage renders metric cards and activity items', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminOverviewPage(),
        ),
      ),
    );

    // Verify 4 metric card labels and values
    expect(find.text('Người dùng nền tảng'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('+2 trong 7 ngày'), findsOneWidget);

    expect(find.text('Tổ chức đang quản lý'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('1 đang thiết lập'), findsOneWidget);

    expect(find.text('Thao tác đặc quyền'), findsOneWidget);
    expect(find.text('126'), findsOneWidget);
    expect(find.text('Trong 24 giờ'), findsOneWidget);

    expect(find.text('Thao tác bị chặn'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Cần rà soát'), findsOneWidget);

    // Verify activity section title and items
    expect(find.text('Hoạt động đặc quyền gần đây'), findsOneWidget);
    expect(find.text('Đã tạm ngừng tổ chức'), findsOneWidget);
    expect(find.text('Từ chối thao tác không đủ quyền'), findsOneWidget);
  });
}
