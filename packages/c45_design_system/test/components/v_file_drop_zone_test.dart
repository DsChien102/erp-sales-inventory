import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  group('VFileDropZone', () {
    Future<void> pumpZone(WidgetTester tester, Widget zone) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(body: zone),
        ),
      );
    }

    testWidgets('renders title and subtitle for each state', (tester) async {
      for (final state in VFileDropZoneState.values) {
        await pumpZone(
          tester,
          VFileDropZone(
            state: state,
            title: 'Title ${state.name}',
            subtitle: 'Subtitle ${state.name}',
            onTap: state == VFileDropZoneState.disabled ? null : () {},
          ),
        );

        expect(find.text('Title ${state.name}'), findsOneWidget);
        expect(find.text('Subtitle ${state.name}'), findsOneWidget);
        expect(find.byType(VFileDropZone), findsOneWidget);
      }
    });

    testWidgets('invokes onTap when enabled', (tester) async {
      var tapped = false;
      await pumpZone(
        tester,
        VFileDropZone(
          title: 'Chọn hoặc kéo tệp',
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(VFileDropZone));
      expect(tapped, isTrue);
    });

    testWidgets('does not invoke onTap when disabled', (tester) async {
      var tapped = false;
      await pumpZone(
        tester,
        VFileDropZone(
          state: VFileDropZoneState.disabled,
          title: 'Chặn quyền',
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(VFileDropZone));
      expect(tapped, isFalse);
    });

    testWidgets('uses fileUp icon for invalid state', (tester) async {
      await pumpZone(
        tester,
        const VFileDropZone(
          state: VFileDropZoneState.invalid,
          title: 'File không hợp lệ',
        ),
      );

      final icon = tester.widget<VIcon>(find.byType(VIcon));
      expect(icon.icon, VIcons.fileUp);
    });

    testWidgets('paints dashed border for all states', (tester) async {
      for (final state in VFileDropZoneState.values) {
        await pumpZone(
          tester,
          VFileDropZone(
            state: state,
            title: 'Dash ${state.name}',
            onTap: state == VFileDropZoneState.disabled ? null : () {},
          ),
        );

        final paints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
        expect(
          paints.any((p) => p.painter != null),
          isTrue,
          reason: 'state ${state.name} should have dashed painter',
        );
      }
    });

    testWidgets('renders action CTA inside the zone', (tester) async {
      var picked = false;
      await pumpZone(
        tester,
        VFileDropZone(
          title: 'Kéo & thả file vào đây',
          subtitle: 'hoặc',
          action: VButton(
            label: 'Chọn file từ thiết bị',
            variant: VButtonVariant.secondary,
            onPressed: () => picked = true,
          ),
        ),
      );

      expect(find.text('Kéo & thả file vào đây'), findsOneWidget);
      expect(find.text('hoặc'), findsOneWidget);
      expect(find.text('Chọn file từ thiết bị'), findsOneWidget);

      await tester.tap(find.text('Chọn file từ thiết bị'));
      expect(picked, isTrue);
    });

    testWidgets('action disables full-zone onTap', (tester) async {
      var zoneTapped = false;
      await pumpZone(
        tester,
        VFileDropZone(
          title: 'Zone',
          onTap: () => zoneTapped = true,
          action: VButton(
            label: 'Pick',
            onPressed: () {},
          ),
        ),
      );

      await tester.tap(find.text('Zone'));
      expect(zoneTapped, isFalse);
    });
  });
}
