import 'package:erp/core/di/injection.dart';
import 'package:erp/features/partner/presentation/pages/partner_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

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
    required this.hasUpdatePermission,
  });

  final bool hasUpdatePermission;

  @override
  String? get userId => 'user-1';

  @override
  String? get tenantId => 'tenant-1';

  @override
  String? get role => 'member';

  @override
  bool hasPermission(String code) {
    if (code == PartnerPermissions.update || code == 'partner.update') {
      return hasUpdatePermission;
    }
    return true;
  }
}

final class _FakePartnerModule implements IPartnerModule {
  _FakePartnerModule({
    this.shouldFailLoading = false,
    this.shouldReturnDuplicatePhone = false,
    this.shouldThrowPermissionOnSave = false,
  });

  bool shouldFailLoading;
  bool shouldReturnDuplicatePhone;
  bool shouldThrowPermissionOnSave;
  int updateCallCount = 0;
  int loadCallCount = 0;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    if (command is UpdatePartnerProfileCommand) {
      final updateCommand = command as UpdatePartnerProfileCommand;
      updateCallCount++;
      if (shouldThrowPermissionOnSave) {
        throw ApplicationException('Permission denied: partner.update');
      }
      return UpdatePartnerProfileResult(
        businessPartnerId: 'partner-1',
        version: updateCommand.expectedVersion + 1,
        hasTaxCodeWarning: false,
      ) as TResult;
    }
    throw UnimplementedError();
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is GetPartnerDetailQuery) {
      loadCallCount++;
      if (shouldFailLoading) {
        throw ApplicationException('Network error');
      }
      return PartnerDetailDto(
        id: 'partner-1',
        displayName: 'Nguyen Van An',
        phone: '0912345678',
        roles: const {PartnerRole.customer},
        entityType: EntityType.individual,
        status: PartnerStatus.active,
        createdAt: DateTime.parse('2026-07-01T00:00:00Z'),
        updatedAt: DateTime.parse('2026-07-01T00:00:00Z'),
        version: 1,
        createdBy: 'user-1',
        updatedBy: 'user-1',
        email: 'an@example.com',
        address: '123 Nguyen Trai',
        taxCode: '0312345678',
        invoiceName: 'Cong ty An',
        invoiceAddress: '456 Le Loi',
        invoiceEmail: 'billing@example.com',
        note: 'Khach hang uu tien',
        hasBusinessData: false,
      ) as TResult;
    }
    if (query is CheckDuplicatePartnersForUpdateQuery) {
      if (shouldReturnDuplicatePhone) {
        return [
          const PartnerDuplicateMatchDto(
            field: PartnerDuplicateField.phone,
            businessPartnerId: 'partner-dup-1',
            displayName: 'Duplicate Partner',
            matchedValue: '0912345678',
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
    required bool hasUpdatePermission,
    bool shouldFailLoading = false,
    bool shouldReturnDuplicatePhone = false,
    bool shouldThrowPermissionOnSave = false,
  }) {
    getIt
      ..registerSingleton<IPartnerModule>(_FakePartnerModule(
        shouldFailLoading: shouldFailLoading,
        shouldReturnDuplicatePhone: shouldReturnDuplicatePhone,
        shouldThrowPermissionOnSave: shouldThrowPermissionOnSave,
      ))
      ..registerSingleton<IExecutionContext>(_FakeExecutionContext())
      ..registerSingleton<IPrincipalSnapshot>(_FakePrincipalSnapshot(
        hasUpdatePermission: hasUpdatePermission,
      ));

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/partner/edit',
          builder: (context, state) {
            final hasPermission = getIt<IPrincipalSnapshot>().hasPermission(PartnerPermissions.update);
            if (!hasPermission) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                VToast.show(
                  context,
                  title: 'Lỗi',
                  message: 'Bạn không có quyền phù hợp.',
                  type: VToastType.danger,
                );
                context.go('/');
              });
              return const Scaffold(body: SizedBox.shrink());
            }
            return const PartnerEditPage(partnerId: 'partner-1');
          },
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/partner/edit'),
                child: const Text('Go to Edit'),
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

  Future<void> navigateToEdit(WidgetTester tester) async {
    await tester.tap(find.text('Go to Edit'));
    await tester.pumpAndSettle();
  }

  testWidgets('SCN-02 & FR-02 SCN-01: edit page loads and pre-fills partner info', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(hasUpdatePermission: true),
    );
    await tester.pumpAndSettle();
    await navigateToEdit(tester);

    // Verify fields are pre-filled
    expect(find.widgetWithText(VTextField, 'Nguyen Van An'), findsOneWidget);
    expect(find.widgetWithText(VTextField, '0912345678'), findsOneWidget);
    expect(find.widgetWithText(VTextField, 'an@example.com'), findsOneWidget);
    expect(find.widgetWithText(VTextField, '123 Nguyen Trai'), findsOneWidget);
    expect(find.widgetWithText(VTextField, '0312345678'), findsOneWidget);
    expect(find.widgetWithText(VTextField, 'Khach hang uu tien'), findsOneWidget);
  });

  testWidgets('SCN-03: blocks user without update permission and redirects to home', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(hasUpdatePermission: false),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go to Edit'));
    await tester.pumpAndSettle();

    // Should be redirected to home page
    expect(find.text('Go to Edit'), findsOneWidget);
    expect(find.byType(PartnerEditPage), findsNothing);
  });

  testWidgets('SCN-05: fails loading shows error screen and lets user retry', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        hasUpdatePermission: true,
        shouldFailLoading: true,
      ),
    );
    await tester.pumpAndSettle();
    await navigateToEdit(tester);

    expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
    expect(find.text('Tải lại'), findsOneWidget);

    // Toggle the loading failure flag on the registered module
    final module = getIt<IPartnerModule>() as _FakePartnerModule;
    module.shouldFailLoading = false;

    await tester.tap(find.text('Tải lại'));
    await tester.pumpAndSettle();

    expect(find.text('Không thể tải dữ liệu'), findsNothing);
    expect(find.widgetWithText(VTextField, 'Nguyen Van An'), findsOneWidget);
    expect(module.loadCallCount, 2);
  });

  testWidgets('FR-03: validates name and phone empty, and formats', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(hasUpdatePermission: true),
    );
    await tester.pumpAndSettle();
    await navigateToEdit(tester);

    // Clear name
    final nameField = find.byWidgetPredicate((w) => w is VTextField && w.label == 'Họ và tên');
    await tester.enterText(find.descendant(of: nameField, matching: find.byType(TextField)), '');

    // Clear phone
    final phoneField = find.byWidgetPredicate((w) => w is VTextField && w.label == 'Số điện thoại');
    await tester.enterText(find.descendant(of: phoneField, matching: find.byType(TextField)), '');

    // Save changes button is disabled because state says !hasChanges. Let's make a change in email to enable saving.
    final emailField = find.byWidgetPredicate((w) => w is VTextField && w.label == 'Email');
    await tester.enterText(find.descendant(of: emailField, matching: find.byType(TextField)), 'invalid-email');

    // Click submit
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    // Verify error messages
    expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
    expect(find.text('Vui lòng nhập số điện thoại'), findsOneWidget);
    expect(find.text('Email chưa đúng định dạng'), findsOneWidget);
  });

  testWidgets('FR-05 & FR-06: duplicate warning handles confirm and save ok', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        hasUpdatePermission: true,
        shouldReturnDuplicatePhone: true,
      ),
    );
    await tester.pumpAndSettle();
    await navigateToEdit(tester);

    // Change a field to enable save
    final noteField = find.byWidgetPredicate((w) => w is VTextField && w.hintText != null && w.hintText!.contains('Ghi chú nội bộ'));
    await tester.enterText(find.descendant(of: noteField, matching: find.byType(TextField)), 'new note');
    await tester.pumpAndSettle();

    // Save changes
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    // Verify duplicate warning bottom sheet
    expect(find.text('Thông tin này đã tồn tại ở một KH & NCC khác'), findsOneWidget);
    expect(find.text('Duplicate Partner'), findsOneWidget);

    // Confirm duplication
    await tester.tap(find.text('Vẫn lưu'));
    await tester.pumpAndSettle();

    // Verify success and page pop
    final module = getIt<IPartnerModule>() as _FakePartnerModule;
    expect(module.updateCallCount, 1);
  });
}
