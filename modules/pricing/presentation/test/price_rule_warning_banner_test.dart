import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_pricing_presentation/presentation.dart';

void main() {
  testWidgets('duplicate banner blocks save and never promises overwrite', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PriceRuleDuplicateBanner())),
    );

    expect(find.textContaining('Không thể lưu'), findsOneWidget);
    expect(find.textContaining('ghi đè'), findsNothing);
  });
}
