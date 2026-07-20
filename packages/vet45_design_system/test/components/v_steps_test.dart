import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VSteps', () {
    testWidgets('renders horizontal layout with automatic statuses', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VSteps(
              steps: [
                VStepItem(title: 'Chủ sở hữu', subtitle: 'Hoàn tất'),
                VStepItem(title: 'Tổ chức', subtitle: 'Đang thực hiện'),
                VStepItem(title: 'Kiểm tra', subtitle: 'Chưa bắt đầu'),
              ],
              currentStep: 1,
            ),
          ),
        ),
      );

      // Verify titles and subtitles
      expect(find.text('Chủ sở hữu'), findsOneWidget);
      expect(find.text('Hoàn tất'), findsOneWidget);
      expect(find.text('Tổ chức'), findsOneWidget);
      expect(find.text('Đang thực hiện'), findsOneWidget);
      expect(find.text('Kiểm tra'), findsOneWidget);
      expect(find.text('Chưa bắt đầu'), findsOneWidget);

      // Verify step indicators: step 1 (completed, icon check), step 2 (active, '2'), step 3 (inactive, '3')
      expect(find.byType(VIcon), findsOneWidget); // Icon check in step 1
      expect(find.text('2'), findsOneWidget); // Step 2 number
      expect(find.text('3'), findsOneWidget); // Step 3 number
    });

    testWidgets('renders horizontal list type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VSteps(
              steps: [
                VStepItem(title: 'Bước 1', subtitle: 'Xong'),
                VStepItem(title: 'Bước 2', subtitle: 'Đang chạy'),
              ],
              currentStep: 0,
              type: VStepsType.list,
              direction: Axis.horizontal,
            ),
          ),
        ),
      );

      expect(find.text('Bước 1'), findsOneWidget);
      expect(find.text('Xong'), findsOneWidget);
      expect(find.text('Bước 2'), findsOneWidget);
      expect(find.text('Đang chạy'), findsOneWidget);
    });

    testWidgets('renders vertical list type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VSteps(
              steps: [
                VStepItem(title: 'Bước 1', subtitle: 'Xong'),
                VStepItem(title: 'Bước 2', subtitle: 'Đang chạy'),
              ],
              currentStep: 0,
              type: VStepsType.list,
              direction: Axis.vertical,
            ),
          ),
        ),
      );

      expect(find.text('Bước 1'), findsOneWidget);
      expect(find.text('Bước 2'), findsOneWidget);
    });
  });
}
