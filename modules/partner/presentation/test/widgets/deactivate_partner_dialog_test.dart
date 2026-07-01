import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_presentation/presentation.dart';

void main() {
  testWidgets('deactivate dialog confirms action', (tester) async {
    var confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => DeactivatePartnerDialog(
                      partner: const PartnerItemModel(
                        id: 'partner-1',
                        avatarText: 'NA',
                        name: 'Nguyen Van An',
                        role: 'Khách hàng',
                        status: 'Đang hoạt động',
                        phone: '0912345678',
                        email: '',
                        taxId: '',
                        updatedAt: '01/07/2026',
                      ),
                      onCancel: () {},
                      onConfirm: () => confirmed = true,
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

    expect(find.text('Ngừng hoạt động đối tác'), findsOneWidget);
    await tester.tap(find.text('Ngừng hoạt động'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });
}
