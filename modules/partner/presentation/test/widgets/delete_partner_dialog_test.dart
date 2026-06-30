import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_presentation/src/widgets/delete_partner_dialog.dart';

void main() {
  testWidgets('shows delete confirmation and returns true when confirmed', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await DeletePartnerDialog.show(
                    context,
                    partnerName: 'Nguyen Van A',
                  );
                },
                child: const Text('Open delete dialog'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open delete dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Xóa hồ sơ đối tác'), findsOneWidget);
    expect(find.textContaining('Nguyen Van A'), findsOneWidget);

    await tester.tap(find.text('Xóa hồ sơ'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('returns false when delete is cancelled', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await DeletePartnerDialog.show(
                    context,
                    partnerName: 'Nguyen Van A',
                  );
                },
                child: const Text('Open delete dialog'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open delete dialog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
