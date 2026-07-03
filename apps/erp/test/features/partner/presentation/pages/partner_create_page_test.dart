import 'package:erp/core/di/injection.dart';
import 'package:erp/features/partner/presentation/pages/partner_create_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class _FakeExecutionContext implements IExecutionContext {
  @override
  String get correlationId => 'test-correlation';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'user-1';
}

final class _FakePrincipalSnapshot implements IPrincipalSnapshot {
  _FakePrincipalSnapshot({
    required this.hasCreatePermission,
  });

  final bool hasCreatePermission;

  @override
  String? get role => 'member';

  @override
  bool hasPermission(String code) {
    if (code == PartnerPermissions.create || code == 'partner.create') {
      return hasCreatePermission;
    }
    return true;
  }
}

final class _FakePartnerModule implements IPartnerModule {
  _FakePartnerModule({
    required this.shouldReturnDuplicateTaxCode,
    required this.shouldThrowPermissionOnSave,
  });

  final bool shouldReturnDuplicateTaxCode;
  final bool shouldThrowPermissionOnSave;
  int registerCallCount = 0;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    if (command is RegisterPartnerCommand) {
      registerCallCount++;
      if (shouldThrowPermissionOnSave) {
        throw ApplicationException('Permission denied: partner.create');
      }
      return RegisterPartnerResult(
        businessPartnerId: 'partner-new-1',
        hasTaxCodeWarning: shouldReturnDuplicateTaxCode,
      ) as TResult;
    }
    throw UnimplementedError();
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is CheckDuplicatePartnersQuery) {
      final dupQuery = query as CheckDuplicatePartnersQuery;
      if (shouldReturnDuplicateTaxCode && dupQuery.taxCode == '12345678') {
        return [
          const PartnerDuplicateMatchDto(
            field: PartnerDuplicateField.taxCode,
            businessPartnerId: 'partner-dup-1',
            displayName: 'Existing Company',
            matchedValue: '12345678',
          ),
        ] as TResult;
      }
      return <PartnerDuplicateMatchDto>[] as TResult;
    }
    throw UnimplementedError('Unexpected query: $query');
  }
}

void main() {
  setUp(() async {
    await getIt.reset();
  });

  Widget buildTestableWidget({
    required bool hasCreatePermission,
    required bool shouldReturnDuplicateTaxCode,
    required bool shouldThrowPermissionOnSave,
  }) {
    getIt
      ..registerSingleton<IPartnerModule>(
        _FakePartnerModule(
          shouldReturnDuplicateTaxCode: shouldReturnDuplicateTaxCode,
          shouldThrowPermissionOnSave: shouldThrowPermissionOnSave,
        ),
      )
      ..registerSingleton<IExecutionContext>(_FakeExecutionContext())
      ..registerSingleton<IPrincipalSnapshot>(
        _FakePrincipalSnapshot(hasCreatePermission: hasCreatePermission),
      );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/partner/create',
          builder: (context, state) => const PartnerCreatePage(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/partner/create'),
                child: const Text('Go to Create'),
              ),
            ),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  Future<void> navigateToCreate(WidgetTester tester) async {
    await tester.tap(find.text('Go to Create'));
    await tester.pumpAndSettle();
  }

  testWidgets('SCN-03 (FR-04): tax code and billing email validations', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        hasCreatePermission: true,
        shouldReturnDuplicateTaxCode: false,
        shouldThrowPermissionOnSave: false,
      ),
    );
    await tester.pumpAndSettle();
    await navigateToCreate(tester);

    // Fill valid name and phone
    final nameField = find.byWidgetPredicate((w) => w is VTextField && w.label == 'Họ và tên');
    expect(nameField, findsOneWidget);
    await tester.enterText(find.descendant(of: nameField, matching: find.byType(TextField)), 'Test Partner');

    final phoneField = find.byWidgetPredicate((w) => w is VTextField && w.label == 'Số điện thoại');
    expect(phoneField, findsOneWidget);
    await tester.enterText(find.descendant(of: phoneField, matching: find.byType(TextField)), '0912345678');

    // Fill invalid tax code
    final taxField = find.byWidgetPredicate((w) => w is VTextField && w.label == 'Mã số thuế');
    expect(taxField, findsOneWidget);
    await tester.enterText(find.descendant(of: taxField, matching: find.byType(TextField)), '123'); // Invalid: < 8 chars

    // Click submit
    await tester.tap(find.text('Lưu KH & NCC'));
    await tester.pumpAndSettle();

    // Tax code error should be visible
    expect(find.text('Mã số thuế chưa đúng định dạng'), findsOneWidget);

    // Enter a tax code that is too long (> 16 digits); field only accepts digits
    await tester.enterText(
      find.descendant(of: taxField, matching: find.byType(TextField)),
      '12345678901234567',
    );
    await tester.pumpAndSettle();

    // Tax code error should be visible because length exceeds 16
    expect(find.text('Mã số thuế chưa đúng định dạng'), findsOneWidget);

    // Correct the tax code
    await tester.enterText(find.descendant(of: taxField, matching: find.byType(TextField)), '12345678');
    await tester.pumpAndSettle();

    // The validation error should disappear when value is valid
    expect(find.text('Mã số thuế chưa đúng định dạng'), findsNothing);
  });

  testWidgets('SCN-02 (FR-05): tax code duplicate warning bottom sheet', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        hasCreatePermission: true,
        shouldReturnDuplicateTaxCode: true,
        shouldThrowPermissionOnSave: false,
      ),
    );
    await tester.pumpAndSettle();
    await navigateToCreate(tester);

    // Fill valid name, phone, and duplicate tax code
    final nameField = find.byWidgetPredicate((w) => w is VTextField && w.label == 'Họ và tên');
    final phoneField = find.byWidgetPredicate((w) => w is VTextField && w.label == 'Số điện thoại');
    final taxField = find.byWidgetPredicate((w) => w is VTextField && w.label == 'Mã số thuế');

    await tester.enterText(find.descendant(of: nameField, matching: find.byType(TextField)), 'Test Partner');
    await tester.enterText(find.descendant(of: phoneField, matching: find.byType(TextField)), '0912345678');
    await tester.enterText(find.descendant(of: taxField, matching: find.byType(TextField)), '12345678');

    // Submit
    await tester.tap(find.text('Lưu KH & NCC'));
    await tester.pumpAndSettle();

    // Warning bottom sheet should be shown
    expect(find.text('Thông tin này đã tồn tại ở một KH & NCC khác'), findsOneWidget);
    expect(find.text('Mã số thuế đang trùng với KH & NCC sau:'), findsOneWidget);
    expect(find.text('Existing Company'), findsOneWidget);
    expect(find.text('Vẫn lưu'), findsOneWidget);

    // Click "Vẫn lưu" (confirm submit)
    await tester.tap(find.text('Vẫn lưu'));
    await tester.pumpAndSettle();

    // Verify command was executed and page popped back to list
    final partnerModule = getIt<IPartnerModule>() as _FakePartnerModule;
    expect(partnerModule.registerCallCount, 1);
    expect(find.text('Go to Create'), findsOneWidget);
  });

  testWidgets('SCN-05 (FR-06): permission revoked at save time displays toast', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        hasCreatePermission: true, // passes initial page load check
        shouldReturnDuplicateTaxCode: false,
        shouldThrowPermissionOnSave: true, // fails inside executeCommandAsync
      ),
    );
    await tester.pumpAndSettle();
    await navigateToCreate(tester);

    // Fill details
    final nameField = find.byWidgetPredicate((w) => w is VTextField && w.label == 'Họ và tên');
    final phoneField = find.byWidgetPredicate((w) => w is VTextField && w.label == 'Số điện thoại');

    await tester.enterText(find.descendant(of: nameField, matching: find.byType(TextField)), 'Test Partner');
    await tester.enterText(find.descendant(of: phoneField, matching: find.byType(TextField)), '0912345678');

    // Submit
    await tester.tap(find.text('Lưu KH & NCC'));
    await tester.pumpAndSettle();

    // Friendly error toast should be visible
    expect(find.text('Bạn không có quyền phù hợp.'), findsOneWidget);
  });
}
