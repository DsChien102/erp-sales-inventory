import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';

void main() {
  testWidgets('wgt_e01_u02_fr01_01: D-01 returns selected partner type', (
    tester,
  ) async {
    PartnerType? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  selected = await showPartnerCreateActionSheet(context);
                },
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();

    expect(find.text('Thêm KH & NCC mới'), findsOneWidget);
    expect(find.text('Tạo cá nhân'), findsOneWidget);
    expect(find.text('Tạo tổ chức'), findsOneWidget);

    await tester.tap(find.byKey(const Key('partner_create_organization')));
    await tester.pumpAndSettle();

    expect(selected, PartnerType.organization);
  });
}
