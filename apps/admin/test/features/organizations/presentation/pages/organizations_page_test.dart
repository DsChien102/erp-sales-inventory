import 'package:admin/features/organizations/presentation/pages/organizations_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('OrganizationsPage Widget Tests', () {
    testWidgets(
      'wgt_e02_u08_fr01_01: renders search bar, filter chips, and list',
      (tester) async {
        final module = FakeIamModule(scenario: FakeIamScenario.tenantsSearchOk);
        getIt
          ..registerSingleton(FakeExecutionContext())
          ..registerSingleton<IIamModule>(module);

        await tester.pumpWidget(
          buildTestableWidget(OrganizationsPage(iamModule: module)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(VSearchBar), findsOneWidget);
        expect(find.byType(OrganizationFilterChips), findsOneWidget);
        expect(find.byType(OrganizationListContent), findsOneWidget);
        expect(find.text('Mậu Hiên'), findsOneWidget);
        expect(find.text('ASC Commerce'), findsOneWidget);
      },
    );

    testWidgets('filters organization list when searching by name', (
      tester,
    ) async {
      final module = FakeIamModule(scenario: FakeIamScenario.tenantsSearchOk);

      await tester.pumpWidget(
        buildTestableWidget(OrganizationsPage(iamModule: module)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'ASC');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('ASC Commerce'), findsOneWidget);
      expect(find.text('Mậu Hiên'), findsNothing);
    });

    testWidgets('filters organization list by status chip', (tester) async {
      final module = FakeIamModule(scenario: FakeIamScenario.tenantsSearchOk);

      await tester.pumpWidget(
        buildTestableWidget(OrganizationsPage(iamModule: module)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thiết lập'));
      await tester.pumpAndSettle();

      expect(find.text('ASC Commerce'), findsOneWidget);
      expect(find.text('Mậu Hiên'), findsNothing);
    });

    testWidgets('shows VEmptyState when search has no matching results', (
      tester,
    ) async {
      final module = FakeIamModule(scenario: FakeIamScenario.tenantsSearchOk);

      await tester.pumpWidget(
        buildTestableWidget(OrganizationsPage(iamModule: module)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'xyz-not-found');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byType(OrganizationEmptyView), findsOneWidget);
    });
  });
}
