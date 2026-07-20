import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VLoading', () {
    testWidgets('renders basic circular indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VLoading(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders task mode with title and description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: VLoading(
              title: 'Đang chuyển tổ chức',
              description: 'Đang tải dữ liệu và quyền truy cập',
            ),
          ),
        ),
      );

      expect(find.text('Đang chuyển tổ chức'), findsOneWidget);
      expect(find.text('Đang tải dữ liệu và quyền truy cập'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows dialog when show is called', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    VLoading.show(
                      context: context,
                      title: 'Dialog Loading',
                      description: 'Loading details',
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 100)); // Finish modal pop transition

      expect(find.text('Dialog Loading'), findsOneWidget);
      expect(find.text('Loading details'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
    });
  });
}
