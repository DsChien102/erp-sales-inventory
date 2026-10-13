import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VSkeleton motion', () {
    Widget host(Widget child, {required bool disableAnimations}) => MaterialApp(
          theme: VTheme.lightTheme,
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: disableAnimations,
            ),
            child: app!,
          ),
          home: Scaffold(body: child),
        );

    testWidgets('standalone bone pulses by default', (tester) async {
      await tester.pumpWidget(
        host(const VSkeleton(width: 100, height: 12), disableAnimations: false),
      );
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('standalone bone is still with reduced motion', (tester) async {
      await tester.pumpWidget(
        host(const VSkeleton(width: 100, height: 12), disableAnimations: true),
      );
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('scope pulses by default', (tester) async {
      await tester.pumpWidget(
        host(
          const VSkeletonScope(child: VSkeleton(width: 100, height: 12)),
          disableAnimations: false,
        ),
      );
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('scope is still with reduced motion', (tester) async {
      await tester.pumpWidget(
        host(
          const VSkeletonScope(child: VSkeleton(width: 100, height: 12)),
          disableAnimations: true,
        ),
      );
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('reacts when the setting changes while mounted', (tester) async {
      const bone = VSkeletonScope(child: VSkeleton(width: 100, height: 12));
      await tester.pumpWidget(host(bone, disableAnimations: false));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(host(bone, disableAnimations: true));
      expect(tester.hasRunningAnimations, isFalse);

      await tester.pumpWidget(host(bone, disableAnimations: false));
      expect(tester.hasRunningAnimations, isTrue);
    });
  });
}
