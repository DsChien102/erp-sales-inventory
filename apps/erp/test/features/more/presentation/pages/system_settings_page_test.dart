import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/more/presentation/pages/system_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<GoRouter> pumpPushed(
  WidgetTester tester, {
  required Size size,
  required Widget page,
  required String path,
  bool push = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: push ? '/more' : path,
    routes: [
      GoRoute(
        path: '/more',
        builder: (_, _) => const Scaffold(body: Text('MORE_PAGE')),
      ),
      GoRoute(path: path, builder: (_, _) => page),
      GoRoute(
        path: '/more/einvoice',
        builder: (_, _) => const VPageScaffold(title: 'HĐĐT', body: SizedBox()),
      ),
      GoRoute(path: '/more/product-settings', builder: (_, _) => const SizedBox()),
      GoRoute(
        path: '/more/roles',
        builder: (_, _) => const VPageScaffold(title: 'ROLES', body: SizedBox()),
      ),
      GoRoute(path: '/more/organization-profile', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/more/users', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/more/audit-logs', builder: (_, _) => const SizedBox()),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: VTheme.lightTheme, routerConfig: router),
  );
  await tester.pumpAndSettle();
  if (push) {
    router.push(path);
    await tester.pumpAndSettle();
  }
  return router;
}

void main() {
  const path = '/more/settings';
  final back = find.byTooltip('Quay lại');

  testWidgets('settings at 390 pushed from /more: has back', (tester) async {
    await pumpPushed(
      tester,
      size: const Size(390, 844),
      page: const SystemSettingsPage(),
      path: path,
    );
    expect(back, findsOneWidget);
  });

  testWidgets('settings at 390 opened directly: no back', (tester) async {
    await pumpPushed(
      tester,
      size: const Size(390, 844),
      page: const SystemSettingsPage(),
      path: path,
      push: false,
    );
    expect(back, findsNothing);
  });

  testWidgets('settings: tap back returns to /more', (tester) async {
    await pumpPushed(
      tester,
      size: const Size(390, 844),
      page: const SystemSettingsPage(),
      path: path,
    );
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text('MORE_PAGE'), findsOneWidget);
  });

  testWidgets('settings at 1280 pushed from /more: no back', (tester) async {
    await pumpPushed(
      tester,
      size: const Size(1280, 800),
      page: const SystemSettingsPage(),
      path: path,
    );
    expect(back, findsNothing);
  });

  testWidgets('settings at 1023 pushed: has back; at 1024: no back', (tester) async {
    await pumpPushed(
      tester,
      size: const Size(1023, 800),
      page: const SystemSettingsPage(),
      path: path,
    );
    expect(back, findsOneWidget);
    tester.view.physicalSize = const Size(1024, 800);
    await tester.pumpAndSettle();
    expect(back, findsNothing);
  });

  testWidgets('settings pushed at 900 then widened to 1280 and back to 900', (tester) async {
    await pumpPushed(
      tester,
      size: const Size(900, 800),
      page: const SystemSettingsPage(),
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

  testWidgets('settings at 1280: child /more/einvoice keeps back', (tester) async {
    await pumpPushed(
      tester,
      size: const Size(1280, 800),
      page: const SystemSettingsPage(),
      path: path,
    );
    await tester.tap(find.text('Thiết lập hóa đơn điện tử'));
    await tester.pumpAndSettle();
    expect(back, findsOneWidget);
  });
}
