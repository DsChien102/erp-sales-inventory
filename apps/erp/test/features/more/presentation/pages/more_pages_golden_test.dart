import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/session/models/session_snapshot.dart';
import 'package:erp/features/more/presentation/bloc/iam_feature_access_cubit.dart';
import 'package:erp/features/more/presentation/pages/system_settings_page.dart';
import 'package:erp/features/more/presentation/pages/users_and_roles_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../iam/support/iam_test_session.dart';
import '../../../inventory/support/inventory_test_surface.dart';
import '../../../receivable/presentation/receivable_test_harness.dart'
    show loadInterFont, repoRoot;

const _owner = SessionSnapshot(
  isAuthenticated: true,
  userId: 'owner-1',
  role: 'store_owner',
  isOwner: true,
);

String _path(String name) =>
    '${repoRoot()}/docs/refactor/plans/P10/img/10-8c/flutter-APP02-$name.png';

/// Dựng trang trần (không khung) như ảnh prototype; đẩy từ `/more` để ca 390 có ←.
Future<void> capture(
  WidgetTester tester, {
  required Size size,
  required String route,
  required Widget page,
  required String name,
}) async {
  useInventoryTestSurface(size);
  final key = GlobalKey();
  final router = GoRouter(
    initialLocation: '/more',
    routes: [
      GoRoute(path: '/more', builder: (_, _) => const Scaffold()),
      GoRoute(path: route, builder: (_, _) => page),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) => RepaintBoundary(key: key, child: child!),
    ),
  );
  await tester.pumpAndSettle();
  router.push(route);
  await tester.pumpAndSettle();
  await expectLater(find.byKey(key), matchesGoldenFile(_path(name)));
}

void main() {
  setUpAll(loadInterFont);

  for (final w in [390, 1280]) {
    final size = Size(w.toDouble(), 844);
    testWidgets('golden settings-default-$w', (tester) async {
      await capture(
        tester,
        size: size,
        route: '/more/settings',
        page: const SystemSettingsPage(),
        name: 'settings-default-$w',
      );
    });
    testWidgets('golden users-owner-$w', (tester) async {
      final cubit = IamFeatureAccessCubit(session: sessionFromSnapshot(_owner));
      await cubit.load();
      addTearDown(cubit.close);
      await capture(
        tester,
        size: size,
        route: '/more/users-and-roles',
        page: UsersAndRolesPage(accessCubit: cubit),
        name: 'users-owner-$w',
      );
    });
  }
}
