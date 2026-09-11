import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/partner/presentation.dart';

void main() {
  testWidgets('history card shows deferred-feature notice without fake activity', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PartnerDetailHistoryCard()),
      ),
    );

    expect(find.text('Tạo mới hồ sơ'), findsNothing);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.text('Lịch sử gần đây'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('Lịch sử làm việc sẽ được phát triển sau.'),
      findsOneWidget,
    );
    expect(find.text('Tạo mới hồ sơ'), findsNothing);
  });
}
