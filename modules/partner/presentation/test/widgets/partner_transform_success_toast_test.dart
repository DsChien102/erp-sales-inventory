import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_presentation/presentation.dart';

void main() {
  testWidgets('shows transform success toast copy and dismiss control', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => showPartnerTransformSuccessToast(context),
                child: const Text('show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();

    expect(find.byKey(const Key('toast_partner_transform_success')), findsOneWidget);
    expect(find.text('Đã chuyển đổi thành công.'), findsOneWidget);
  });
}
