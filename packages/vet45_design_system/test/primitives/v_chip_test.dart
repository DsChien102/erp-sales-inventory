import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VChip', () {
    final colors = VColorScheme.light;

    Widget wrap(Widget child) {
      return MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(body: child),
      );
    }

    BoxDecoration decorationOf(WidgetTester tester) {
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(VChip),
              matching: find.byType(Container),
            )
            .first,
      );
      return container.decoration! as BoxDecoration;
    }

    Color labelColorOf(WidgetTester tester, String label) {
      return tester.widget<Text>(find.text(label)).style!.color!;
    }

    testWidgets('defaults to neutral tone', (tester) async {
      await tester.pumpWidget(wrap(const VChip(label: 'Neutral')));

      final decoration = decorationOf(tester);
      expect(decoration.color, colors.surfaceAlt);
      expect(decoration.border!.top.color, colors.borderStrong);
      expect(labelColorOf(tester, 'Neutral'), colors.textPrimary);
    });

    testWidgets('primary tone uses surfaceBrand, textBrand and borderBrand', (tester) async {
      await tester.pumpWidget(
        wrap(const VChip(label: 'Primary', tone: VComponentTone.primary)),
      );

      final decoration = decorationOf(tester);
      expect(decoration.color, colors.surfaceBrand);
      expect(decoration.border!.top.color, colors.borderBrand);
      expect(labelColorOf(tester, 'Primary'), colors.textBrand);
    });

    testWidgets('semantic tones border with their own foreground color', (tester) async {
      await tester.pumpWidget(
        wrap(const VChip(label: 'Danger', tone: VComponentTone.danger)),
      );

      final decoration = decorationOf(tester);
      expect(decoration.color, colors.dangerBg);
      expect(decoration.border!.top.color, colors.danger);
      expect(labelColorOf(tester, 'Danger'), colors.danger);
    });

    testWidgets('ambient VComponentScope tone is inherited', (tester) async {
      await tester.pumpWidget(
        wrap(
          vProvideComponentScope(
            tone: VComponentTone.warning,
            child: const VChip(label: 'Ambient'),
          ),
        ),
      );

      expect(decorationOf(tester).color, colors.warningBg);
      expect(labelColorOf(tester, 'Ambient'), colors.warning);
    });

    testWidgets('local tone wins over ambient scope', (tester) async {
      await tester.pumpWidget(
        wrap(
          vProvideComponentScope(
            tone: VComponentTone.warning,
            child: const VChip(label: 'Local', tone: VComponentTone.info),
          ),
        ),
      );

      expect(decorationOf(tester).color, colors.infoBg);
      expect(labelColorOf(tester, 'Local'), colors.info);
    });

    testWidgets('deprecated selected bridges to primary tone', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VChip(
            label: 'Selected',
            // ignore: deprecated_member_use
            selected: true,
          ),
        ),
      );

      expect(decorationOf(tester).color, colors.surfaceBrand);
      expect(labelColorOf(tester, 'Selected'), colors.textBrand);
    });

    testWidgets('deprecated emphasis bridges to a tone', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Column(
            children: [
              VChip(
                label: 'Strong',
                // ignore: deprecated_member_use
                emphasis: VComponentEmphasis.strong,
              ),
              VChip(
                label: 'Subtle',
                // ignore: deprecated_member_use
                emphasis: VComponentEmphasis.subtle,
              ),
            ],
          ),
        ),
      );

      expect(labelColorOf(tester, 'Strong'), colors.textBrand);
      expect(labelColorOf(tester, 'Subtle'), colors.textPrimary);
    });

    testWidgets('explicit tone wins over deprecated selected', (tester) async {
      await tester.pumpWidget(
        wrap(
          const VChip(
            label: 'Both',
            tone: VComponentTone.danger,
            // ignore: deprecated_member_use
            selected: true,
          ),
        ),
      );

      expect(decorationOf(tester).color, colors.dangerBg);
    });

    testWidgets('disabled chip is dimmed and does not fire onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          VChip(
            label: 'Disabled',
            enabled: false,
            onTap: () => taps++,
          ),
        ),
      );

      expect(find.byType(Opacity), findsWidgets);
      await tester.tap(find.text('Disabled'));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('icon and remove control never exceed the label line height', (tester) async {
      final lineHeight = VTypography.bodySmall.fontSize! * VTypography.bodySmall.height!;

      await tester.pumpWidget(
        wrap(
          VChip(
            label: 'Tag',
            icon: VIcons.tag,
            onRemove: () {},
          ),
        ),
      );

      final labelHeight = tester.getSize(find.text('Tag')).height;
      for (final icon in find.byType(VIcon).evaluate()) {
        expect(tester.getSize(find.byWidget(icon.widget)).height, lessThanOrEqualTo(labelHeight));
      }
      expect(labelHeight, lineHeight);
    });

    testWidgets('onRemove shows a dismiss control that fires', (tester) async {
      var removed = 0;
      await tester.pumpWidget(
        wrap(
          VChip(
            label: 'Tag',
            tone: VComponentTone.info,
            onRemove: () => removed++,
          ),
        ),
      );

      final removeIcon = find.byWidgetPredicate(
        (w) => w is VIcon && w.icon == VIcons.close,
      );
      expect(removeIcon, findsOneWidget);
      expect(tester.widget<VIcon>(removeIcon).color, colors.info);

      await tester.tap(removeIcon);
      await tester.pump();
      expect(removed, 1);
    });

    group('touch target', () {
      Widget host(Widget chip) => wrap(Align(alignment: Alignment.topLeft, child: chip));

      testWidgets('onRemove: layout box is 44 high, drawn chip keeps its size', (tester) async {
        await tester.pumpWidget(host(VChip(label: 'Tag', onRemove: () {})));
        final chipBox = tester.getSize(find.byType(VChip));
        final drawn = tester.getSize(
          find.descendant(of: find.byType(VChip), matching: find.byType(Container)).first,
        );

        expect(chipBox.height, VSpacing.minTouchTarget);
        expect(drawn.height, lessThan(VSpacing.minTouchTarget));
      });

      testWidgets('no onRemove: chip size is unchanged', (tester) async {
        await tester.pumpWidget(host(const VChip(label: 'Tag')));
        expect(
          tester.getSize(find.byType(VChip)).height,
          lessThan(VSpacing.minTouchTarget),
        );
      });

      testWidgets('onTap chip has a 44px touch target', (tester) async {
        await tester.pumpWidget(host(VChip(label: 'Tag', onTap: () {})));
        expect(
          tester.getSize(find.byType(VChip)).height,
          VSpacing.minTouchTarget,
        );
      });

      testWidgets('onTap: drawn chip keeps its size', (tester) async {
        await tester.pumpWidget(host(const VChip(label: 'Tag')));
        final staticHeight = tester.getSize(find.byType(VChip)).height;

        await tester.pumpWidget(host(VChip(label: 'Tag', onTap: () {})));
        final drawn = tester.getSize(
          find.descendant(of: find.byType(VChip), matching: find.byType(Container)).first,
        );

        expect(drawn.height, staticHeight);
        expect(drawn.height, lessThan(44));
      });

      testWidgets('onTap: does not expand width when width is >= 44', (tester) async {
        await tester.pumpWidget(host(const VChip(label: 'Tag with a long label')));
        final staticWidth = tester.getSize(find.byType(VChip)).width;
        expect(staticWidth, greaterThanOrEqualTo(44));

        await tester.pumpWidget(host(VChip(label: 'Tag with a long label', onTap: () {})));
        final tapWidth = tester.getSize(find.byType(VChip)).width;
        expect(tapWidth, staticWidth);
      });

      testWidgets('onTap: tapping near top and bottom edge of 44 frame triggers onTap', (tester) async {
        var taps = 0;
        await tester.pumpWidget(host(VChip(label: 'Tag', onTap: () => taps++)));

        final r = tester.getRect(find.byType(VChip));
        await tester.tapAt(Offset(r.center.dx, r.top + 2));
        await tester.pump();
        await tester.tapAt(Offset(r.center.dx, r.bottom - 2));
        await tester.pump();

        expect(taps, 2);
      });

      testWidgets('tail 44×44 region calls onRemove, rest calls onTap', (tester) async {
        var taps = 0;
        var removed = 0;
        await tester.pumpWidget(
          host(
            VChip(
              label: 'Tag',
              onTap: () => taps++,
              onRemove: () => removed++,
            ),
          ),
        );
        final rect = tester.getRect(find.byType(VChip));

        // 20px from the right edge: beyond the icon's left side but inside 44.
        await tester.tapAt(Offset(rect.right - 40, rect.center.dy));
        expect(removed, 1);
        expect(taps, 0);

        await tester.tapAt(Offset(rect.left + 6, rect.center.dy));
        expect(removed, 1);
        expect(taps, 1);
      });

      testWidgets('disabled chip ignores remove', (tester) async {
        var removed = 0;
        await tester.pumpWidget(
          host(VChip(label: 'Tag', enabled: false, onRemove: () => removed++)),
        );
        final rect = tester.getRect(find.byType(VChip));
        await tester.tapAt(Offset(rect.right - 10, rect.center.dy));
        expect(removed, 0);
      });

      testWidgets('remove control has a named button role', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(VChip(label: 'Tag', onRemove: () {})));

        final node = tester.getSemantics(find.bySemanticsLabel('Xóa Tag'));
        expect(node.label, 'Xóa Tag');
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        handle.dispose();
      });

      testWidgets('isSelected is exposed through semantics', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          host(VChip(label: 'Tag', isSelected: true, onTap: () {})),
        );

        final node = tester.getSemantics(find.byType(VChip));
        expect(node.flagsCollection.isSelected, Tristate.isTrue);
        handle.dispose();
      });

      testWidgets('meets iOS tap target and labelled guidelines', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          host(VChip(label: 'Tag', onTap: () {}, onRemove: () {})),
        );
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    });
  });
}
