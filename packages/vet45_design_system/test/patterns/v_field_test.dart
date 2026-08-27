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
}
