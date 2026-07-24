import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:admin/features/users/presentation/pages/platform_users_page.dart';

void main() {
  testWidgets('PlatformUsersPage shows search bar and filter button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlatformUsersPage(),
        ),
      ),
    );

    expect(find.byType(VSearchBar), findsOneWidget);
    expect(find.byIcon(VIcons.tune.value), findsOneWidget);
  });

  testWidgets('PlatformUsersPage shows loadError empty state when hasError is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlatformUsersPage(hasError: true),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Không thể tải danh sách'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('PlatformUsersPage shows unauthorized empty state when isUnauthorized is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlatformUsersPage(isUnauthorized: true),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bạn không có quyền xem'), findsOneWidget);
    expect(find.text('Quay lại'), findsOneWidget);
  });

  testWidgets('PlatformUsersPage search debounce works', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlatformUsersPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(VSearchBar), 'Nguyen');
    await tester.pump();

    // Wait for debounce timer (300ms)
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
  });

  testWidgets('PlatformUsersPage support pull-to-refresh', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlatformUsersPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Trigger pull-to-refresh on the ListView
    await tester.fling(find.byType(ListView), const Offset(0.0, 300.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
