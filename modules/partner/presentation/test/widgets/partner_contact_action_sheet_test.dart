import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';

void main() {
  testWidgets('remove action is returned after the sheet closes', (tester) async {
    PartnerContactAction? selectedAction;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selectedAction = await showModalBottomSheet<PartnerContactAction>(
                context: context,
                builder: (_) => const PartnerContactActionSheet(
                  contact: PartnerContactDto(
                    personPartnerId: 'person-1',
                    displayName: 'Nguyễn Văn An',
                    isPrimary: true,
                  ),
                ),
              );
            },
            child: const Text('Mở'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gỡ khỏi tổ chức'));
    await tester.pumpAndSettle();

    expect(selectedAction, PartnerContactAction.remove);
    expect(find.text('Thao tác'), findsNothing);
  });

  testWidgets('set-primary action is returned after the sheet closes', (tester) async {
    PartnerContactAction? selectedAction;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selectedAction = await showModalBottomSheet<PartnerContactAction>(
                context: context,
                builder: (_) => const PartnerContactActionSheet(
                  contact: PartnerContactDto(
                    personPartnerId: 'person-2',
                    displayName: 'Trần Thị Bình',
                    isPrimary: false,
                  ),
                ),
              );
            },
            child: const Text('Mở'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt làm chính'));
    await tester.pumpAndSettle();

    expect(selectedAction, PartnerContactAction.setPrimary);
    expect(find.text('Thao tác'), findsNothing);
  });

  testWidgets('inactive contact cannot be set as primary', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const PartnerContactActionSheet(
                contact: PartnerContactDto(
                  personPartnerId: 'person-inactive',
                  displayName: 'Lê Văn C',
                  isPrimary: false,
                  status: PartnerStatus.inactive,
                ),
              ),
            ),
            child: const Text('Mở'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();

    expect(find.text('Đặt làm chính'), findsNothing);
    expect(find.text('Chỉnh sửa liên hệ'), findsOneWidget);
    expect(find.text('Gỡ khỏi tổ chức'), findsOneWidget);
  });
}
