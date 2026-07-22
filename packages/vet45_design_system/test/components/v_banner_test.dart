import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VBanner', () {
    Future<void> pumpBanner(WidgetTester tester, Widget banner) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(body: banner),
        ),
      );
    }

    testWidgets('renders title and description for each status', (tester) async {
      for (final status in VBannerStatus.values) {
        await pumpBanner(
          tester,
          VBanner(
            status: status,
            title: 'Tiêu đề ${status.name}',
            description: 'Mô tả ${status.name}',
          ),
        );

        expect(find.text('Tiêu đề ${status.name}'), findsOneWidget);
        expect(find.text('Mô tả ${status.name}'), findsOneWidget);
        expect(find.byType(VBanner), findsOneWidget);
      }
    });

    testWidgets('hides description when null', (tester) async {
      await pumpBanner(
        tester,
        const VBanner(
          status: VBannerStatus.info,
          title: 'Chỉ tiêu đề',
        ),
      );

      expect(find.text('Chỉ tiêu đề'), findsOneWidget);
      expect(find.byType(VText), findsOneWidget);
    });
  });
}
