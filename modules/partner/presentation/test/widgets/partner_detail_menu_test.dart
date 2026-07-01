import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_presentation/src/bloc/partner_list_state.dart';
import 'package:vet45_partner_presentation/src/widgets/partner_detail_menu.dart';

void main() {
  testWidgets('shows delete action only when canDelete is true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerDetailMenu(
            partner: const PartnerItemModel(
              id: 'partner-1',
              avatarText: 'NA',
              name: 'Nguyen Van A',
              role: 'Khách hàng',
              status: 'Đang hoạt động',
              phone: '0912345678',
              email: '',
              taxId: '',
              updatedAt: '08:00 01/07/2026',
            ),
            canDelete: true,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    expect(find.text('Xóa hồ sơ'), findsOneWidget);
  });

  testWidgets('hides delete action when canDelete is false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerDetailMenu(
            partner: const PartnerItemModel(
              id: 'partner-1',
              avatarText: 'NA',
              name: 'Nguyen Van A',
              role: 'Khách hàng',
              status: 'Đang hoạt động',
              phone: '0912345678',
              email: '',
              taxId: '',
              updatedAt: '08:00 01/07/2026',
            ),
            canDelete: false,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    expect(find.text('Xóa hồ sơ'), findsNothing);
  });
}
