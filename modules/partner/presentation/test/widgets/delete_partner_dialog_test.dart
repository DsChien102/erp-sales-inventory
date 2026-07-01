import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_presentation/presentation.dart';

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

    expect(find.text('Xóa KH & NCC?'), findsOneWidget);
    expect(find.textContaining('danh sách quản lý'), findsOneWidget);

    await tester.tap(find.text('Xóa KH & NCC'));
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
