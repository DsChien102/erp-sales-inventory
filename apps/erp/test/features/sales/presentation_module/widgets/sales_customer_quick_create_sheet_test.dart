import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/sales/presentation.dart';

void main() {
  testWidgets('creates and returns backend customer when no duplicate exists', (
    tester,
  ) async {
    SalesQuickCustomerDraft? submitted;
    bool? submittedConfirmDuplicate;
    SalesCustomerSelection? result;

    await _pumpHost(
      tester,
      onOpen: (context) async {
        result = await SalesCustomerQuickCreateSheet.show(
          context,
          checkDuplicate: (_) async => null,
          createCustomer: (draft, {required confirmDuplicate}) async {
            submitted = draft;
            submittedConfirmDuplicate = confirmDuplicate;
            return SalesCustomerSelection(
              isWalkIn: false,
              partnerId: 'partner-new',
              displayName: draft.displayName,
              phone: draft.phone,
            );
          },
        );
      },
    );

    await tester.tap(find.byKey(const Key('open_sheet')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('input_sg04_quick_name')),
      'Nguyen Van B',
    );
    await tester.enterText(
      find.byKey(const Key('input_sg04_quick_phone')),
      '0988 123 456',
    );
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(submitted?.displayName, 'Nguyen Van B');
    expect(submitted?.phone, '0988 123 456');
    expect(submittedConfirmDuplicate, isFalse);
    expect(result?.partnerId, 'partner-new');
    expect(result?.displayName, 'Nguyen Van B');
  });

  testWidgets('choosing duplicate returns existing customer without create', (
    tester,
  ) async {
    var createCalls = 0;
    SalesCustomerSelection? result;

    await _pumpHost(
      tester,
      onOpen: (context) async {
        result = await SalesCustomerQuickCreateSheet.show(
          context,
          checkDuplicate: (_) async => const SalesCustomerListItemVm(
            partnerId: 'partner-existing',
            displayName: 'Khach cu',
            phone: '0903456789',
          ),
          createCustomer: (_, {required confirmDuplicate}) async {
            createCalls++;
            return const SalesCustomerSelection(
              isWalkIn: false,
              partnerId: 'partner-new',
              displayName: 'Khach moi',
            );
          },
        );
      },
    );

    await tester.tap(find.byKey(const Key('open_sheet')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('input_sg04_quick_name')),
      'Khach cu',
    );
    await tester.enterText(
      find.byKey(const Key('input_sg04_quick_phone')),
      '0903456789',
    );
    await _tapSubmit(tester);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('btn_sg04_duplicate_choose_existing')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(createCalls, 0);
    expect(result?.partnerId, 'partner-existing');
  });

  testWidgets('force creating duplicate forwards confirmDuplicate true', (
    tester,
  ) async {
    bool? submittedConfirmDuplicate;

    await _pumpHost(
      tester,
      onOpen: (context) async {
        await SalesCustomerQuickCreateSheet.show(
          context,
          checkDuplicate: (_) async => const SalesCustomerListItemVm(
            partnerId: 'partner-existing',
            displayName: 'Khach cu',
            phone: '0903456789',
          ),
          createCustomer: (_, {required confirmDuplicate}) async {
            submittedConfirmDuplicate = confirmDuplicate;
            return const SalesCustomerSelection(
              isWalkIn: false,
              partnerId: 'partner-new',
              displayName: 'Khach moi',
            );
          },
        );
      },
    );

    await tester.tap(find.byKey(const Key('open_sheet')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('input_sg04_quick_name')),
      'Khach moi',
    );
    await tester.enterText(
      find.byKey(const Key('input_sg04_quick_phone')),
      '0903456789',
    );
    await _tapSubmit(tester);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('btn_sg04_duplicate_force_create')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(submittedConfirmDuplicate, isTrue);
  });

  testWidgets('backend exception keeps entered text and shows error', (
    tester,
  ) async {
    await _pumpHost(
      tester,
      onOpen: (context) async {
        await SalesCustomerQuickCreateSheet.show(
          context,
          checkDuplicate: (_) async => null,
          createCustomer: (_, {required confirmDuplicate}) async {
            throw const SalesCustomerOperationException('Mat ket noi');
          },
        );
      },
    );

    await tester.tap(find.byKey(const Key('open_sheet')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('input_sg04_quick_name')),
      'Nguyen Van B',
    );
    await tester.enterText(
      find.byKey(const Key('input_sg04_quick_phone')),
      '0988123456',
    );
    await _tapSubmit(tester);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Mat ket noi'), findsOneWidget);
    expect(find.text('Nguyen Van B', skipOffstage: false), findsOneWidget);
    expect(find.text('0988123456', skipOffstage: false), findsOneWidget);
  });

  testWidgets('tax code field formats 13-digit and sets number keyboard', (tester) async {
    await _pumpHost(
      tester,
      onOpen: (context) async {
        await SalesCustomerQuickCreateSheet.show(
          context,
          checkDuplicate: (_) async => null,
          createCustomer: (draft, {required confirmDuplicate}) async => const SalesCustomerSelection(
            isWalkIn: false,
            partnerId: 'p1',
            displayName: 'Test',
          ),
        );
      },
    );

    await tester.tap(find.byKey(const Key('open_sheet')));
    await tester.pumpAndSettle();

    final taxFieldFinder = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Ví dụ: 0101234567',
    );
    expect(taxFieldFinder, findsOneWidget);
    final taxField = tester.widget<TextField>(taxFieldFinder);
    expect(taxField.keyboardType, TextInputType.number);

    await tester.enterText(taxFieldFinder, '0123456789001');
    await tester.pumpAndSettle();

    expect(find.text('0123456789-001'), findsOneWidget);
  });
}

Future<void> _tapSubmit(WidgetTester tester) async {
  final submit = find.byKey(const Key('btn_sg04_quick_create_submit'));
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pump();
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required Future<void> Function(BuildContext context) onOpen,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: VTheme.lightTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => VButton(
            key: const Key('open_sheet'),
            label: 'Open',
            onPressed: () => onOpen(context),
          ),
        ),
      ),
    ),
  );
}
