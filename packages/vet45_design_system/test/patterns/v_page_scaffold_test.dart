import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

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
  });

  group('VPagePadding', () {
    test('horizontalForWidth uses breakpoint tokens', () {
      expect(VPagePadding.horizontalForWidth(390), VSpacing.screenMobile);
      expect(VPagePadding.horizontalForWidth(800), VSpacing.screenTablet);
      expect(VPagePadding.horizontalForWidth(1200), VSpacing.screenDesktop);
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
  });
}
