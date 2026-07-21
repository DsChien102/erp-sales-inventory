import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_presentation/presentation.dart';

void main() {
  testWidgets('PlatformUserEmptyView renders correctly for noUsers state', (
    WidgetTester tester,
  ) async {
    bool isClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlatformUserEmptyView(
            type: PlatformUserEmptyStateType.noUsers,
            onAction: () {
              isClicked = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Chưa có người dùng nền tảng'), findsOneWidget);
    expect(
      find.text('Thêm người dùng đầu tiên để bắt đầu quản trị tài khoản.'),
      findsOneWidget,
    );
    expect(find.text('Thêm người dùng'), findsOneWidget);

    await tester.tap(find.text('Thêm người dùng'));
    await tester.pump();

    expect(isClicked, isTrue);
  });

  testWidgets('PlatformUserEmptyView renders correctly for noResults state', (
    WidgetTester tester,
  ) async {
    bool isClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlatformUserEmptyView(
            type: PlatformUserEmptyStateType.noResults,
            onAction: () {
              isClicked = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Không tìm thấy người dùng'), findsOneWidget);
    expect(
      find.text('Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.'),
      findsOneWidget,
    );
    expect(find.text('Xóa bộ lọc'), findsOneWidget);

    await tester.tap(find.text('Xóa bộ lọc'));
    await tester.pump();

    expect(isClicked, isTrue);
  });

  testWidgets('PlatformUserEmptyView renders correctly for loadError state', (
    WidgetTester tester,
  ) async {
    bool isClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlatformUserEmptyView(
            type: PlatformUserEmptyStateType.loadError,
            onAction: () {
              isClicked = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Không thể tải danh sách'), findsOneWidget);
    expect(
      find.text('Đã xảy ra lỗi khi tải người dùng. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.text('Thử lại'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pump();

    expect(isClicked, isTrue);
  });

  testWidgets('PlatformUserEmptyView renders correctly for unauthorized state', (
    WidgetTester tester,
  ) async {
    bool isClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlatformUserEmptyView(
            type: PlatformUserEmptyStateType.unauthorized,
            onAction: () {
              isClicked = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Bạn không có quyền xem'), findsOneWidget);
    expect(
      find.text(
        'Liên hệ chủ cửa hàng để được cấp quyền quản lý người dùng nền tảng.',
      ),
      findsOneWidget,
    );
    expect(find.text('Quay lại'), findsOneWidget);

    await tester.tap(find.text('Quay lại'));
    await tester.pump();

    expect(isClicked, isTrue);
  });
}
