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

  group('VComponentScope.resolveTone', () {
    testWidgets('returns local when set', (tester) async {
      VComponentTone? resolved;
      await tester.pumpWidget(
        wrap(
          VComponentScope(
            tone: VComponentTone.warning,
            child: Builder(
              builder: (context) {
                resolved = VComponentScope.resolveTone(
                  context,
                  local: VComponentTone.danger,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(resolved, VComponentTone.danger);
    });

    testWidgets('falls back to nearest scope tone', (tester) async {
      VComponentTone? resolved;
      await tester.pumpWidget(
        wrap(
          VComponentScope(
            tone: VComponentTone.warning,
            child: Builder(
              builder: (context) {
                resolved = VComponentScope.resolveTone(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(resolved, VComponentTone.warning);
    });

    testWidgets('returns null when no local and no scope', (tester) async {
      VComponentTone? resolved;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              resolved = VComponentScope.resolveTone(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved, isNull);
    });

    testWidgets('nested scope overrides outer', (tester) async {
      VComponentTone? resolved;
      await tester.pumpWidget(
        wrap(
          VComponentScope(
            tone: VComponentTone.warning,
            child: VComponentScope(
              tone: VComponentTone.info,
              child: Builder(
                builder: (context) {
                  resolved = VComponentScope.resolveTone(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      expect(resolved, VComponentTone.info);
    });
  });

  group('VComponentScope.resolveEnabled', () {
    testWidgets('returns local when set', (tester) async {
      late bool resolved;
      await tester.pumpWidget(
        wrap(
          VComponentScope(
            enabled: false,
            child: Builder(
              builder: (context) {
                resolved = VComponentScope.resolveEnabled(
                  context,
                  local: true,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(resolved, isTrue);
    });

    testWidgets('falls back to nearest scope enabled', (tester) async {
      late bool resolved;
      await tester.pumpWidget(
        wrap(
          VComponentScope(
            enabled: false,
            child: Builder(
              builder: (context) {
                resolved = VComponentScope.resolveEnabled(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(resolved, isFalse);
    });

    testWidgets('returns fallback when no local and no scope', (tester) async {
      late bool resolved;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              resolved = VComponentScope.resolveEnabled(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved, isTrue);
    });
  });

  group('requireAncestor', () {
    testWidgets('throws when ancestor missing', (tester) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              requireAncestor<VComponentScope>(
                context,
                widgetName: 'Child',
                ancestorName: 'VComponentScope',
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(tester.takeException(), isA<FlutterError>());
    });
  });
}
