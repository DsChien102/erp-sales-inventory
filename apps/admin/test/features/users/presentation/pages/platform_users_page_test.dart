import 'package:admin/features/users/presentation/pages/platform_users_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  testWidgets(
    'wgt_e01_u01_fr01_01: PlatformUsersPage shows search bar and filter button',
    (WidgetTester tester) async {
      final module = FakeIamModule();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlatformUsersPage(iamModule: module)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VSearchBar), findsOneWidget);
      expect(find.byIcon(VIcons.tune.value), findsOneWidget);
    },
  );

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
    'PlatformUsersPage shows noResults with Xóa bộ lọc when search-only matches nothing',
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
      expect(find.text('Xóa bộ lọc'), findsOneWidget);

      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pumpAndSettle();

      expect(find.text('Lê Thị Lan'), findsOneWidget);
    },
  );

  testWidgets(
    'PlatformUsersPage clearing search from the empty state reloads the list',
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

      // No results → the empty state offers "Xóa bộ lọc" to reset the search.
      expect(find.text('Không tìm thấy người dùng'), findsOneWidget);

      await tester.tap(find.text('Xóa bộ lọc'));
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

  testWidgets(
    'PlatformUsersPage leaves primary name blank when backend only has email fallback',
    (WidgetTester tester) async {
      final module = _EmailFallbackIamModule();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlatformUsersPage(iamModule: module)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Không có tên'), findsNothing);
      expect(find.text('longhjk345@gmail.com'), findsOneWidget);
    },
  );
}

final class _EmailFallbackIamModule implements IIamModule {
  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('No commands are used by this test.');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is SearchPlatformUsersQuery) {
      return CursorPageDto<PlatformUserSummaryDto>(
            items: [
              PlatformUserSummaryDto(
                userId: 'user-email-fallback',
                fullName: 'longhjk345@gmail.com',
                email: 'longhjk345@gmail.com',
                status: PlatformUserStatus.active,
                createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
              ),
            ],
          )
          as TResult;
    }
    throw UnsupportedError('Unsupported query ${query.runtimeType}');
  }
}
