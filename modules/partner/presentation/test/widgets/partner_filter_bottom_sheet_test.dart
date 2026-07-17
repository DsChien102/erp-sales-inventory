import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_presentation/presentation.dart';

void main() {
  testWidgets('updated-time options share one row and custom has calendar icon', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PartnerFilterBottomSheet(
            initialRole: null,
            initialPartnerType: null,
            initialStatus: null,
            initialUpdatedTimeFilter: null,
          ),
        ),
      ),
    );

    final timeRow = find.byKey(const Key('partner_updated_time_filters'));

    expect(timeRow, findsOneWidget);
    expect(
      find.descendant(of: timeRow, matching: find.text('30 ngày gần đây')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: timeRow, matching: find.text('Tùy chọn')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: timeRow,
        matching: find.byIcon(VIcons.calendar.value),
      ),
      findsOneWidget,
    );

    final roleStyle = tester.widget<Text>(find.text('Khách hàng')).style;
    final timeStyle = tester.widget<Text>(find.text('7 ngày gần đây')).style;
    expect(timeStyle?.fontSize, roleStyle?.fontSize);
    expect(timeStyle?.fontWeight, roleStyle?.fontWeight);
    expect(timeStyle?.color, roleStyle?.color);
  });

  testWidgets('applying seven-day preset returns selected time filter', (
    tester,
  ) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await PartnerFilterBottomSheet.show(context);
              },
              child: const Text('Mở bộ lọc'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở bộ lọc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 ngày gần đây'));
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();

    expect(result?['updatedTimeFilter'], PartnerUpdatedTimeFilter.last7Days);
  });
}
