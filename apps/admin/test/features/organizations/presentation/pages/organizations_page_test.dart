import 'package:admin/features/organizations/presentation/pages/organizations_page.dart';
import 'package:admin/features/organizations/presentation/pages/platform_onboarding_page.dart';
import 'package:admin/features/dashboard/presentation/dashboard_page.dart';
import 'package:admin/features/dashboard/presentation/models/admin_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';
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
    return MaterialApp(home: Scaffold(body: child));
  }

  group('OrganizationsPage Widget Tests', () {
    testWidgets('dashboard shell does not show a hard-coded tenant count', (
      tester,
    ) async {
      final module = _EmptyPlatformTenantModule();
      getIt
        ..registerSingleton(FakeExecutionContext())
        ..registerSingleton<IIamModule>(module);

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            builder: (_, _) => const DashboardPage(initialTab: AdminTab.organizations),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Tổ chức'), findsOneWidget);
      expect(find.text('18 tổ chức'), findsNothing);
      expect(find.text('Chưa có tổ chức'), findsOneWidget);
    });

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

    testWidgets('opens onboarding wizard from empty organization CTA', (
      tester,
    ) async {
      final module = _EmptyPlatformTenantModule();

      await tester.pumpWidget(
        buildTestableWidget(OrganizationsPage(iamModule: module)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có tổ chức'), findsOneWidget);

      await tester.tap(find.text('Khởi tạo tổ chức'));
      await tester.pumpAndSettle();

      expect(find.byType(PlatformOnboardingPage), findsOneWidget);
    });
  });
}

final class _EmptyPlatformTenantModule implements IIamModule {
  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnsupportedError('Unexpected command ${command.runtimeType}');
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is SearchPlatformTenantsQuery) {
      return const CursorPageDto<PlatformTenantSummaryDto>(items: []) as TResult;
    }
    if (query is SearchPlatformUsersQuery) {
      return const CursorPageDto<PlatformUserSummaryDto>(items: []) as TResult;
    }
    throw UnsupportedError('Unexpected query ${query.runtimeType}');
  }
}
