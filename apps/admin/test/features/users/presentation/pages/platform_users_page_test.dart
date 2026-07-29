import 'package:admin/features/users/presentation/pages/platform_users_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';

void main() {
  testWidgets('PlatformUsersPage shows search bar and filter button', (
    WidgetTester tester,
  ) async {
    final module = FakeIamModule();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PlatformUsersPage(iamModule: module)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(VSearchBar), findsOneWidget);
    expect(find.byIcon(VIcons.tune.value), findsOneWidget);
  });

  testWidgets(
    'PlatformUsersPage shows loadError empty state when hasError is true',
    (WidgetTester tester) async {
      final module = FakeIamModule();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlatformUsersPage(iamModule: module, hasError: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Không thể tải danh sách'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    },
  );

  testWidgets(
    'PlatformUsersPage shows unauthorized empty state when isUnauthorized is true',
    (WidgetTester tester) async {
      final module = FakeIamModule();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlatformUsersPage(iamModule: module, isUnauthorized: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bạn không có quyền xem'), findsOneWidget);
      expect(find.text('Quay lại'), findsOneWidget);
    },
  );

  testWidgets('PlatformUsersPage search debounce works', (
    WidgetTester tester,
  ) async {
    final module = FakeIamModule();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PlatformUsersPage(iamModule: module)),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(VSearchBar), 'Nguyen');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'PlatformUsersPage shows noResults with Xóa tìm kiếm when search-only matches nothing',
    (WidgetTester tester) async {
      final module = FakeIamModule();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlatformUsersPage(iamModule: module)),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(VSearchBar), 'dasdasdas');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy người dùng'), findsOneWidget);
      expect(find.text('Xóa tìm kiếm'), findsOneWidget);
      expect(find.byIcon(VIcons.close.value), findsOneWidget);

      await tester.tap(find.text('Xóa tìm kiếm'));
      await tester.pumpAndSettle();

      expect(find.text('Lê Thị Lan'), findsOneWidget);
    },
  );

  testWidgets(
    'PlatformUsersPage tapping x icon on VSearchBar clears search and reloads list',
    (WidgetTester tester) async {
      final module = FakeIamModule();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlatformUsersPage(iamModule: module)),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(VSearchBar), 'dasdasdas');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byIcon(VIcons.close.value), findsOneWidget);

      await tester.tap(find.byIcon(VIcons.close.value));
      await tester.pumpAndSettle();

      expect(find.text('Lê Thị Lan'), findsOneWidget);
    },
  );

  testWidgets('PlatformUsersPage support pull-to-refresh', (
    WidgetTester tester,
  ) async {
    final module = FakeIamModule();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PlatformUsersPage(iamModule: module)),
      ),
    );

    await tester.pumpAndSettle();

    await tester.fling(find.byType(ListView), const Offset(0.0, 300.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
