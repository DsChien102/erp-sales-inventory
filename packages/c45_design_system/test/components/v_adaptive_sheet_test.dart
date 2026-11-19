import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  group('showVAdaptiveSheet', () {
    testWidgets('màn rộng >= 1024: mở VSheetDialog dạng hộp thoại căn giữa, tooltip Đóng', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showVAdaptiveSheet<void>(
                    context: context,
                    title: 'Bộ lọc',
                    child: const Text('Nội dung bộ lọc'),
                  );
                },
                child: const Text('Mở sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở sheet'));
      await tester.pumpAndSettle();

      // On wide screen: VSheetDialog is rendered
      expect(find.byType(VSheetDialog), findsOneWidget);
      expect(find.text('Bộ lọc'), findsOneWidget);
      expect(find.text('Nội dung bộ lọc'), findsOneWidget);
      expect(find.byTooltip('Đóng'), findsOneWidget);

      // Tap close button dismisses
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();

      expect(find.byType(VSheetDialog), findsNothing);
    });

    testWidgets('màn rộng >= 1024: nhấn phím Escape đóng hộp thoại', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showVAdaptiveSheet<void>(
                    context: context,
                    title: 'Bộ lọc',
                    child: const Text('Nội dung bộ lọc'),
                  );
                },
                child: const Text('Mở sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(VSheetDialog), findsOneWidget);

      // Press Escape key
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(VSheetDialog), findsNothing);
    });

    testWidgets('màn rộng >= 1024 và title == null: không có VDivider header, nút đóng vẫn hoạt động', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showVAdaptiveSheet<void>(
                    context: context,
                    child: const Text('Nội dung không tiêu đề'),
                  );
                },
                child: const Text('Mở sheet không tiêu đề'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở sheet không tiêu đề'));
      await tester.pumpAndSettle();

      expect(find.byType(VSheetDialog), findsOneWidget);
      expect(find.byType(VDivider), findsNothing);
      expect(find.text('Nội dung không tiêu đề'), findsOneWidget);
      expect(find.byTooltip('Đóng'), findsOneWidget);

      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();

      expect(find.byType(VSheetDialog), findsNothing);
    });

    testWidgets('màn hẹp < 1024: mở modal bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showVAdaptiveSheet<void>(
                    context: context,
                    title: 'Bộ lọc hẹp',
                    child: const Text('Nội dung sheet hẹp'),
                  );
                },
                child: const Text('Mở sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở sheet'));
      await tester.pumpAndSettle();

      // On narrow screen: VBottomSheet is rendered, VSheetDialog is not
      expect(find.byType(VSheetDialog), findsNothing);
      expect(find.byType(VBottomSheet), findsOneWidget);
      expect(find.text('Bộ lọc hẹp'), findsOneWidget);
      expect(find.text('Nội dung sheet hẹp'), findsOneWidget);
    });
  });
}
