import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  group('VField ancestry', () {
    testWidgets('parts require VField ancestor', (tester) async {
      FlutterErrorDetails? caught;
      final old = FlutterError.onError;
      FlutterError.onError = (details) => caught = details;
      addTearDown(() => FlutterError.onError = old);

      await tester.pumpWidget(
        wrap(const VFieldLabel('Email')),
      );
      expect(caught, isNotNull);
      expect(
        caught!.exception.toString(),
        contains('VFieldLabel'),
      );
    });

    testWidgets('parts render inside VField', (tester) async {
      await tester.pumpWidget(
        wrap(
          VField(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                VFieldLabel('Email', isRequired: true),
                SizedBox(height: 8),
                VFieldDescription('Helper'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Email'), findsOneWidget);
      expect(find.text(' *'), findsOneWidget);
      expect(find.text('Helper'), findsOneWidget);
    });
  });

  group('VFieldDescription / VFieldError', () {
    testWidgets('description uses textSecondary', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VField(
            child: VFieldDescription('Hint'),
          ),
        ),
      );
      final text = tester.widget<VText>(find.byType(VText));
      expect(text.color, VColorScheme.light.textSecondary);
    });

    testWidgets('error uses danger', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VField(
            invalid: true,
            child: VFieldError('Bad value'),
          ),
        ),
      );
      final text = tester.widget<VText>(find.byType(VText));
      expect(text.color, VColorScheme.light.danger);
    });
  });

  group('vFieldShell / legacy flat', () {
    testWidgets('error wins helper', (tester) async {
      await tester.pumpWidget(
        wrap(
          vFieldShell(
            control: const SizedBox(height: 8),
            label: 'Email',
            helperText: 'Helper',
            errorText: 'Error',
          ),
        ),
      );
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Helper'), findsNothing);
    });

    testWidgets('VTextField flat props still render via shell', (tester) async {
      await tester.pumpWidget(
        wrap(
          // ignore: deprecated_member_use
          const VTextField(
            // ignore: deprecated_member_use
            label: 'Phone',
            // ignore: deprecated_member_use
            helperText: 'SMS ok',
            // ignore: deprecated_member_use
            isRequired: true,
            hintText: '090…',
          ),
        ),
      );
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('SMS ok'), findsOneWidget);
      expect(find.text(' *'), findsOneWidget);
    });
  });

  group('VField.resolveInvalid', () {
    testWidgets('local wins ambient', (tester) async {
      late bool resolved;
      await tester.pumpWidget(
        wrap(
          VField(
            invalid: true,
            child: Builder(
              builder: (context) {
                resolved = VField.resolveInvalid(context, local: false);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(resolved, isFalse);
    });

    testWidgets('inherits ambient when local is null', (tester) async {
      late bool resolved;
      await tester.pumpWidget(
        wrap(
          VField(
            invalid: true,
            child: Builder(
              builder: (context) {
                resolved = VField.resolveInvalid(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(resolved, isTrue);
    });

    testWidgets('fallback false outside VField', (tester) async {
      late bool resolved;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              resolved = VField.resolveInvalid(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved, isFalse);
    });
  });

  group('VField invalid cascade to controls', () {
    Color? inputBorderColor(WidgetTester tester) {
      for (final element in find.byType(DecoratedBox).evaluate()) {
        final box = element.widget as DecoratedBox;
        final decoration = box.decoration;
        if (decoration is BoxDecoration && decoration.border is Border) {
          final border = decoration.border! as Border;
          if (border.top.color == VColorScheme.light.danger ||
              border.top.color == VColorScheme.light.borderDefault) {
            return border.top.color;
          }
        }
      }
      return null;
    }

    testWidgets('VTextField inherits VField.invalid danger chrome', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VField(
            invalid: true,
            child: VTextField(hintText: 'Email'),
          ),
        ),
      );
      expect(inputBorderColor(tester), VColorScheme.light.danger);
    });

    testWidgets('VTextField local invalid:false overrides ambient', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VField(
            invalid: true,
            child: VTextField(hintText: 'Email', invalid: false),
          ),
        ),
      );
      expect(inputBorderColor(tester), VColorScheme.light.borderDefault);
    });

    testWidgets('legacy errorText still forces danger when invalid null', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          // ignore: deprecated_member_use
          const VTextField(
            hintText: 'Email',
            // ignore: deprecated_member_use
            errorText: 'Required',
          ),
        ),
      );
      expect(inputBorderColor(tester), VColorScheme.light.danger);
    });

    testWidgets('VCombobox inherits VField.invalid danger chrome', (tester) async {
      await tester.pumpWidget(
        wrap(
          VField(
            invalid: true,
            child: VCombobox<String>(
              value: null,
              onChanged: (_) {},
              displayTextForValue: (_) => '',
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VComboboxContent(
                    child: VComboboxList(
                      children: [
                        VComboboxItem(value: 'a', child: Text('Alpha')),
                      ],
                    ),
                  ),
                  VComboboxInput(hintText: 'Pick'),
                ],
              ),
            ),
          ),
        ),
      );
      expect(inputBorderColor(tester), VColorScheme.light.danger);
    });
  });
}
