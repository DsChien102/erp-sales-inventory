import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

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

    testWidgets('deprecated message still resolves body', (tester) async {
      await pumpBanner(
        tester,
        VBanner(
          tone: VComponentTone.danger,
          title: 'Trùng giá riêng',
          // ignore: deprecated_member_use
          message: 'Sẽ ghi đè giá cũ.',
          footer: const VText('Xem chi tiết'),
        ),
      );

      expect(find.text('Trùng giá riêng'), findsOneWidget);
      expect(find.text('Sẽ ghi đè giá cũ.'), findsOneWidget);
      expect(find.text('Xem chi tiết'), findsOneWidget);
    });

    testWidgets('decoration includes semantic border', (tester) async {
      await pumpBanner(
        tester,
        const VBanner(
          status: VBannerStatus.warning,
          title: 'Cảnh báo',
          description: 'Nội dung',
        ),
      );

      final decorated = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      final withBorder = decorated.where((box) {
        final decoration = box.decoration;
        return decoration is BoxDecoration && decoration.border != null;
      });
      expect(withBorder, isNotEmpty);
    });

    testWidgets('description and footer indent past icon column', (tester) async {
      await pumpBanner(
        tester,
        VBanner(
          status: VBannerStatus.info,
          title: 'Tiêu đề',
          description: 'Mô tả thẳng hàng title',
          footer: const VText('Footer CTA'),
        ),
      );

      final titleLeft = tester.getTopLeft(find.text('Tiêu đề')).dx;
      final descriptionLeft = tester.getTopLeft(find.text('Mô tả thẳng hàng title')).dx;
      final footerLeft = tester.getTopLeft(find.text('Footer CTA')).dx;

      expect(descriptionLeft, moreOrLessEquals(titleLeft, epsilon: 0.5));
      expect(footerLeft, moreOrLessEquals(titleLeft, epsilon: 0.5));

      final bannerLeft = tester.getTopLeft(find.byType(VBanner)).dx;
      expect(
        descriptionLeft - bannerLeft,
        greaterThanOrEqualTo(VBanner.contentIndent),
      );
    });

    testWidgets('icon and title share one centered row', (tester) async {
      await pumpBanner(
        tester,
        const VBanner(
          status: VBannerStatus.success,
          title: 'Thành công',
          description: 'Chi tiết bên dưới',
        ),
      );

      final titleCenterY = tester.getCenter(find.text('Thành công')).dy;
      final iconFinder = find.descendant(
        of: find.byType(VBanner),
        matching: find.byType(VIcon),
      );
      expect(iconFinder, findsOneWidget);
      final iconCenterY = tester.getCenter(iconFinder).dy;
      expect(iconCenterY, moreOrLessEquals(titleCenterY, epsilon: 2));
    });
  });
}
