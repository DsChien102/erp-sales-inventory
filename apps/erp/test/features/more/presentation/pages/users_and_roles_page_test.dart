import 'package:erp/features/more/presentation/bloc/iam_feature_access_cubit.dart';
import 'package:erp/features/more/presentation/pages/users_and_roles_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

import '../../../iam/support/iam_module_repositories.dart';

const _owner = SessionDto(
  isAuthenticated: true,
  userId: 'owner-1',
  role: 'store_owner',
  isOwner: true,
);

void main() {
  testWidgets(
    'UsersAndRolesPage renders hub cards without ownership',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = IamFeatureAccessCubit(session: sessionFromDto(_owner));
      await cubit.load();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: UsersAndRolesPage(accessCubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Người dùng & vai trò'), findsWidgets);
      expect(find.text('Cần hoàn tất'), findsNothing);
      expect(find.text('Hồ sơ tổ chức'), findsOneWidget);
      expect(find.text('Người dùng'), findsOneWidget);
      expect(find.text('Vai trò'), findsOneWidget);
      expect(find.text('Quyền sở hữu'), findsNothing);
      expect(find.text('Lịch sử quản trị'), findsOneWidget);
    },
  );

  testWidgets('UsersAndRolesPage opens roles instead of a coming-soon toast', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = IamFeatureAccessCubit(session: sessionFromDto(_owner));
    await cubit.load();
    addTearDown(cubit.close);

    final router = GoRouter(
      initialLocation: '/more/users-and-roles',
      routes: [
        GoRoute(
          path: '/more/users-and-roles',
          builder: (context, state) => UsersAndRolesPage(accessCubit: cubit),
        ),
        GoRoute(
          path: '/more/roles',
          builder: (context, state) => const Scaffold(body: Text('ROLES')),
        ),
        GoRoute(
          path: '/more/organization-profile',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/more/users',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/more/audit-logs',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: VTheme.lightTheme,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vai trò'));
    await tester.pumpAndSettle();

    expect(find.text('ROLES'), findsOneWidget);
    expect(find.text('Chức năng làm sau'), findsNothing);
    expect(find.text('Quyền sở hữu'), findsNothing);
  });

  testWidgets('UsersAndRolesPage supports pull-to-refresh', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = IamFeatureAccessCubit(
      session: sessionFromDto(
        const SessionDto(
          isAuthenticated: true,
          userId: 'owner-1',
          role: 'store_owner',
          isOwner: true,
          tenantId: 'org-001',
        ),
      ),
    );
    await cubit.load();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: UsersAndRolesPage(accessCubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    final refreshIndicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    await refreshIndicator.onRefresh();
    await tester.pumpAndSettle();

    expect(find.text('Vai trò'), findsOneWidget);
    expect(find.text('Quyền sở hữu'), findsNothing);
  });
}
