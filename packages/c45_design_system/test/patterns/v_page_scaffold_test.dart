import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  group('VPageScaffold', () {
    testWidgets('renders title and body', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: VPageScaffold(
            title: 'Test Page',
            subtitle: 'Subtitle',
            showBackButton: false,
            body: const VText('Body content', variant: VTextVariant.bodyDefault),
          ),
        ),
      );

      expect(find.text('Test Page'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.text('Body content'), findsOneWidget);
    });

    testWidgets('renders bottom bar when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: VPageScaffold(
            title: 'Test',
            showBackButton: false,
            body: const SizedBox.shrink(),
            bottomBar: const VButton(label: 'Save', onPressed: null),
          ),
        ),
      );

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('bottom bar is separated by a hairline, not a shadow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: VPageScaffold(
            title: 'Test',
            showBackButton: false,
            body: const SizedBox.shrink(),
            bottomBar: const VText('Bar', variant: VTextVariant.bodyDefault),
          ),
        ),
      );

      final bar = find.ancestor(
        of: find.text('Bar'),
        matching: find.byType(Material),
      );
      expect(tester.widget<Material>(bar.first).elevation, 0);
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find.ancestor(of: find.text('Bar'), matching: find.byType(DecoratedBox)).last,
                  )
                  .decoration
              as BoxDecoration;
      expect((decoration.border! as Border).top.width, VBorders.thin);
    });
  });

  group('VPageScaffold width adaptation', () {
    Future<void> pump(
      WidgetTester tester,
      Size size, {
      VResponsiveValue<double>? contentMaxWidth,
      EdgeInsets padding = EdgeInsets.zero,
    }) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: MediaQuery(
            data: MediaQueryData(size: size, padding: padding),
            child: VPageScaffold(
              title: 'T',
              showBackButton: false,
              contentMaxWidth: contentMaxWidth ?? VPageScaffold.defaultContentMaxWidth,
              body: const SizedBox.expand(key: Key('body')),
              bottomBar: const SizedBox(key: Key('bar'), height: 56),
              floatingActionButton: const SizedBox(key: Key('fab'), width: 56, height: 56),
            ),
          ),
        ),
      );
    }

    testWidgets('phone: body and bottom bar span the window', (tester) async {
      await pump(tester, const Size(400, 800));
      expect(tester.getSize(find.byKey(const Key('body'))).width, 400);
      expect(tester.getSize(find.byKey(const Key('bar'))).width, 400);
    });

    testWidgets('tablet portrait: single centered column', (tester) async {
      await pump(tester, const Size(810, 1080));
      final body = tester.getRect(find.byKey(const Key('body')));
      expect(body.width, 640);
      expect(body.center.dx, 405);
      expect(body.height, greaterThan(800), reason: 'height constraint stays tight');
      expect(tester.getSize(find.byKey(const Key('bar'))).width, 640);
    });

    testWidgets('landscape counter tablet: desktop-width column', (tester) async {
      await pump(tester, const Size(1180, 820));
      expect(tester.getSize(find.byKey(const Key('body'))).width, 720);
    });

    testWidgets('fab follows the column trailing edge', (tester) async {
      await pump(tester, const Size(1180, 820));
      final body = tester.getRect(find.byKey(const Key('body')));
      final fab = tester.getRect(find.byKey(const Key('fab')));
      expect(fab.right, lessThanOrEqualTo(body.right));
      expect(body.right - fab.right, lessThanOrEqualTo(VSpacing.md));
    });

    testWidgets('fullWidth opts out of the column', (tester) async {
      await pump(tester, const Size(1180, 820), contentMaxWidth: VPageScaffold.fullWidth);
      expect(tester.getSize(find.byKey(const Key('body'))).width, 1180);
    });

    testWidgets('landscape phone keeps the body clear of the notch', (tester) async {
      await pump(
        tester,
        const Size(500, 390),
        padding: const EdgeInsets.only(left: 47, right: 47),
      );
      final body = tester.getRect(find.byKey(const Key('body')));
      expect(body.left, 47);
      expect(body.right, 453);
    });
  });

  group('VSection', () {
    testWidgets('renders title subtitle and child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VSection(
              title: 'Section title',
              subtitle: 'Section subtitle',
              child: VText('Child', variant: VTextVariant.bodyDefault),
            ),
          ),
        ),
      );

      expect(find.text('Section title'), findsOneWidget);
      expect(find.text('Section subtitle'), findsOneWidget);
      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('keeps a gap between a long title and the trailing action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: SizedBox(
              width: 280,
              child: VSection(
                title: 'Rất dài ' * 12,
                trailing: const SizedBox(key: Key('trailing'), width: 60, height: 44),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      final title = tester.getRect(find.byType(VText).first);
      final trailing = tester.getRect(find.byKey(const Key('trailing')));
      expect(trailing.left - title.right, greaterThanOrEqualTo(VSpacing.sm));
      expect(tester.takeException(), isNull);
    });
  });
}
