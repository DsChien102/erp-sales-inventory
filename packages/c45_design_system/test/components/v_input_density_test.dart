import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:c45_design_system/src/components/v_input.dart';

void main() {
  testWidgets('VInput locked height matches VButton medium via VDensity', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: const Scaffold(
          body: Column(
            children: [
              VInput(hintText: 'Field'),
              VButton(label: 'Action', onPressed: null),
            ],
          ),
        ),
      ),
    );

    final expected = VDensity.comfortable.controlHeightMedium;
    final inputBox = tester.getSize(find.byType(VInput));
    final button = tester.widget<TextButton>(find.byType(TextButton));
    final buttonHeight = button.style?.fixedSize?.resolve({})?.height;

    expect(inputBox.height, expected);
    expect(buttonHeight, expected);
  });

  Widget host(Widget child, {double textScale = 1, double width = 320}) {
    return MaterialApp(
      theme: VTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );
  }

  group('VInput hardening', () {
    testWidgets('multi-line grows past the control height', (tester) async {
      final controller = TextEditingController(
        text: List.filled(6, 'Dòng ghi chú khá dài').join('\n'),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(VInput(controller: controller, maxLines: null, minLines: 2)),
      );
      expect(
        tester.getSize(find.byType(VInput)).height,
        greaterThan(VDensity.comfortable.controlHeightMedium),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('obscureText with maxLines > 1 does not assert', (tester) async {
      await tester.pumpWidget(
        host(const VInput(obscureText: true, maxLines: 3, minLines: 2)),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(VInput)).height,
        VDensity.comfortable.controlHeightMedium,
      );
    });

    testWidgets('single line grows with large text scale, no overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const VInput(hintText: 'Tìm theo tên, mã vạch hoặc nhà cung cấp rất dài'),
          textScale: 3,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(VInput)).height,
        greaterThan(VDensity.comfortable.controlHeightMedium),
      );
    });

    testWidgets('long hint stays on one line at default scale', (tester) async {
      await tester.pumpWidget(
        host(
          const VInput(
            hintText: 'Một gợi ý rất dài vượt quá chiều rộng của ô nhập liệu để kiểm tra cắt bớt',
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(VInput)).height,
        VDensity.comfortable.controlHeightMedium,
      );
    });

    testWidgets('second finger does not hide a drag from the first', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(
          Column(
            children: [
              VInput(focusNode: focus),
              const SizedBox(height: 300, width: 300),
            ],
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      expect(focus.hasFocus, isTrue);

      final first = await tester.startGesture(const Offset(100, 250), pointer: 1);
      final second = await tester.startGesture(const Offset(200, 250), pointer: 2);
      await first.moveBy(const Offset(0, -80));
      await first.up();
      await second.up();
      await tester.pump();
      expect(focus.hasFocus, isTrue, reason: 'scroll drag keeps focus');
    });
  });
}
