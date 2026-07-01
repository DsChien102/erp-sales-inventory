import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_presentation/presentation.dart';

void main() {
  testWidgets('wgt_e02_u01_fr04_01 reactivate dialog confirms action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  ReactivatePartnerDialog.show(
                    context,
                    partner: const PartnerItemModel(
                      id: 'partner-1',
                      avatarText: 'NA',
                      name: 'Nguyen Van An',
                      role: 'Khách hàng',
                      status: 'Ngừng hoạt động',
                      phone: '0912345678',
                      email: '',
                      taxId: '',
                      updatedAt: '01/07/2026',
                    ),
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
    await tester.pumpAndSettle();

    expect(find.text('Kích hoạt lại KH & NCC?'), findsOneWidget);
    await tester.tap(find.text('Kích hoạt lại'));
    await tester.pumpAndSettle();

    expect(find.text('Kích hoạt lại KH & NCC?'), findsNothing);
  });
}
