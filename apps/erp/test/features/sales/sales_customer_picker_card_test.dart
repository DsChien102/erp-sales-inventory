import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/presentation.dart';

void main() {
  testWidgets('SalesCustomerPickerCard renders selected state with radio dot indicator', (
    tester,
  ) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SalesCustomerPickerCard(
            title: 'Khách lẻ',
            subtitle: 'Không phát sinh công nợ',
            selected: true,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Khách lẻ'), findsOneWidget);
    expect(find.text('Không phát sinh công nợ'), findsOneWidget);

    await tester.tap(find.text('Khách lẻ'));
    expect(tapped, isTrue);
  });

  testWidgets('SalesCustomerPickerCard renders unselected state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SalesCustomerPickerCard(
            title: 'Nguyễn Văn An',
            subtitle: '0912 345 678 · KH-0124',
            selected: false,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('0912 345 678 · KH-0124'), findsOneWidget);
  });
}
