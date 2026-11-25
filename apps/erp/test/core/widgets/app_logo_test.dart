import 'package:erp/core/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => Future.error(FlutterError('missing $key'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AppLogo renders at size, no semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: AppLogo(size: 64)))),
    );
    expect(tester.getSize(find.byType(AppLogo)), const Size(64, 64));
    expect(find.byType(Image), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppLogo), matching: find.byType(ExcludeSemantics)),
      findsWidgets,
    );
    handle.dispose();
  });

  test('icon bytes load', () async {
    final bytes = await loadAppIconBytes();
    expect(bytes, isNotNull);
    expect(bytes, isNotEmpty);
  });

  test('missing asset returns null', () async {
    expect(await loadAppIconBytes(bundle: _FailingBundle()), isNull);
  });
}
