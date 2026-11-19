import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

import '../../inventory/support/inventory_test_surface.dart';

const phone = Size(390, 844);
const web = Size(1280, 800);

/// Bọc [child] trong MaterialApp + GoRouter nhỏ, ghi lại location đã điều hướng.
class RouteLog {
  final List<String> locations = [];
}

Future<void> pumpReceivable(
  WidgetTester tester,
  Widget child, {
  Size size = phone,
  RouteLog? log,
  List<BlocProvider> providers = const [],
  bool settle = true,
}) async {
  useInventoryTestSurface(size);
  final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (_, _) => child),
      GoRoute(
        path: '/more/receivables/:id',
        builder: (_, s) {
          log?.locations.add(s.uri.toString());
          return const Scaffold(body: Text('detail'));
        },
      ),
      GoRoute(
        path: '/sales/orders/:id',
        builder: (_, s) {
          log?.locations.add(s.uri.toString());
          return const Scaffold(body: Text('order'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: VTheme.lightTheme, routerConfig: router),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

String repoRoot() => Directory.current.path.endsWith('apps/erp')
    ? Directory.current.parent.parent.path
    : Directory.current.path;

/// Nạp Inter của design system: mặc định `flutter test` dùng Ahem (ô vuông, rộng hơn chữ thật)
/// nên tràn dòng giả và golden không so được với prototype.
Future<void> loadInterFont() async {
  final loader = FontLoader('packages/c45_design_system/Inter');
  final dir = '${repoRoot()}/packages/c45_design_system/assets/fonts/ttf_Inter';
  for (final f in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    final bytes = await File('$dir/Inter-$f.ttf').readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}
