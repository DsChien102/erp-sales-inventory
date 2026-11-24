import 'package:erp/features/more/presentation/bloc/iam_feature_access_cubit.dart';
import 'package:erp/features/more/presentation/pages/users_and_roles_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/session/models/session_snapshot.dart';
import '../../../iam/support/iam_test_session.dart';
import 'system_settings_page_test.dart' show pumpPushed;

const _owner = SessionSnapshot(
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

      final cubit = IamFeatureAccessCubit(session: sessionFromSnapshot(_owner));
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

    final cubit = IamFeatureAccessCubit(session: sessionFromSnapshot(_owner));
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
      session: sessionFromSnapshot(
        const SessionSnapshot(
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

  Future<IamFeatureAccessCubit> ownerCubit(WidgetTester tester) async {
    final cubit = IamFeatureAccessCubit(session: sessionFromSnapshot(_owner));
    await cubit.load();
    addTearDown(cubit.close);
    return cubit;
  }

  const path = '/more/users-and-roles';
  final back = find.byTooltip('Quay lại');

  testWidgets('users-and-roles at 390 pushed from /more: has back', (tester) async {
    final cubit = await ownerCubit(tester);
    await pumpPushed(
      tester,
      size: const Size(390, 844),
      page: UsersAndRolesPage(accessCubit: cubit),
      path: path,
    );
    expect(back, findsOneWidget);
  });

  testWidgets('users-and-roles at 390 opened directly: no back', (tester) async {
    final cubit = await ownerCubit(tester);
    await pumpPushed(
      tester,
      size: const Size(390, 844),
      page: UsersAndRolesPage(accessCubit: cubit),
      path: path,
      push: false,
    );
    expect(back, findsNothing);
  });

  testWidgets('users-and-roles: tap back returns to /more', (tester) async {
    final cubit = await ownerCubit(tester);
    await pumpPushed(
      tester,
      size: const Size(390, 844),
      page: UsersAndRolesPage(accessCubit: cubit),
      path: path,
    );
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text('MORE_PAGE'), findsOneWidget);
  });

  testWidgets('users-and-roles at 1280 pushed from /more: no back', (tester) async {
    final cubit = await ownerCubit(tester);
    await pumpPushed(
      tester,
      size: const Size(1280, 800),
      page: UsersAndRolesPage(accessCubit: cubit),
      path: path,
    );
    expect(back, findsNothing);
  });

  testWidgets('users-and-roles at 1023 pushed: has back; at 1024: no back', (tester) async {
    final cubit = await ownerCubit(tester);
    await pumpPushed(
      tester,
      size: const Size(1023, 800),
      page: UsersAndRolesPage(accessCubit: cubit),
      path: path,
    );
    expect(back, findsOneWidget);
    tester.view.physicalSize = const Size(1024, 800);
    await tester.pumpAndSettle();
    expect(back, findsNothing);
  });

  testWidgets('users-and-roles pushed at 900 then widened to 1280 and back to 900', (tester) async {
    final cubit = await ownerCubit(tester);
    await pumpPushed(
      tester,
      size: const Size(900, 800),
      page: UsersAndRolesPage(accessCubit: cubit),
      path: path,
    );
    expect(back, findsOneWidget);
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    expect(back, findsNothing);
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(900, 800);
    await tester.pumpAndSettle();
    expect(back, findsOneWidget);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text('MORE_PAGE'), findsOneWidget);
  });

  testWidgets('users-and-roles at 1280: child /more/roles keeps back', (tester) async {
    final cubit = await ownerCubit(tester);
    await pumpPushed(
      tester,
      size: const Size(1280, 800),
      page: UsersAndRolesPage(accessCubit: cubit),
      path: path,
    );
    await tester.tap(find.text('Vai trò'));
    await tester.pumpAndSettle();
    expect(back, findsOneWidget);
  });
}
