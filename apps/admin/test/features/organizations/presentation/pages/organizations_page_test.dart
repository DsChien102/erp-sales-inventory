import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/organizations/presentation/pages/organizations_page.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_presentation/presentation.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('OrganizationsPage Widget Tests', () {
    testWidgets('renders search bar, filter chips, and initial organization list', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const OrganizationsPage()));
      await tester.pumpAndSettle();

      // Verify Search bar
      expect(find.byType(VSearchBar), findsOneWidget);
      expect(find.byType(OrganizationFilterChips), findsOneWidget);
      expect(find.byType(OrganizationListContent), findsOneWidget);
      expect(find.text('Mậu Hiền'), findsOneWidget);
      expect(find.text('ASC Commerce'), findsOneWidget);
    });

    testWidgets('filters organization list when searching by name', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const OrganizationsPage()));
      await tester.pumpAndSettle();

      // Enter "ASC" in search bar
      await tester.enterText(find.byType(TextField), 'ASC');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verify ASC Commerce is displayed while Mậu Hiền is not
      expect(find.text('ASC Commerce'), findsOneWidget);
      expect(find.text('Mậu Hiền'), findsNothing);
    });

    testWidgets('filters organization list by status chip', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const OrganizationsPage()));
      await tester.pumpAndSettle();

      // Tap "Thiết lập" filter chip
      await tester.tap(find.text('Thiết lập'));
      await tester.pumpAndSettle();

      // Verify ASC Commerce (settingUp) is displayed while Mậu Hiền (active) is not
      expect(find.text('ASC Commerce'), findsOneWidget);
      expect(find.text('Mậu Hiền'), findsNothing);
    });

    testWidgets('shows VEmptyState when search has no matching results', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const OrganizationsPage()));
      await tester.pumpAndSettle();

      // Enter non-existent name
      await tester.enterText(find.byType(TextField), 'NonExistentOrg123');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verify empty state
      expect(find.text('Không tìm thấy tổ chức'), findsOneWidget);
      expect(find.byType(OrganizationEmptyView), findsOneWidget);
    });
  });
}
