import 'package:erp/core/di/injection.dart';
import 'package:erp/features/partner/presentation/pages/partner_detail_page.dart';
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

final class _FakePrincipalSnapshot implements IPrincipalSnapshot {
  _FakePrincipalSnapshot({
    required this.permissions,
  });

  Set<String> permissions;

  @override
  String? get role => 'member';

  @override
  bool hasPermission(String code) {
    return permissions.contains(code);
  }
}

final class _FakePartnerModule implements IPartnerModule {
  _FakePartnerModule({
    this.shouldFailLoading = false,
    this.hasBusinessData = false,
    this.status = PartnerStatus.active,
  });

  bool shouldFailLoading;
  bool hasBusinessData;
  PartnerStatus status;
  int loadCallCount = 0;
  int deleteCallCount = 0;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    if (command is DeletePartnerCommand) {
      deleteCallCount++;
      return null as TResult;
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
        status: status,
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
        hasBusinessData: hasBusinessData,
      ) as TResult;
    }
    throw UnimplementedError('Unexpected query: $query');
  }
}

void main() {
  setUp(() async {
    await getIt.reset();
  });

  Widget buildTestableWidget({
    required Set<String> permissions,
    bool shouldFailLoading = false,
    bool hasBusinessData = false,
    String initialStatus = 'Đang hoạt động',
    bool passInitialPartner = true,
  }) {
    final statusEnum = initialStatus == 'Ngừng hoạt động'
        ? PartnerStatus.inactive
        : PartnerStatus.active;

    getIt
      ..registerSingleton<IPartnerModule>(_FakePartnerModule(
        shouldFailLoading: shouldFailLoading,
        hasBusinessData: hasBusinessData,
        status: statusEnum,
      ))
      ..registerSingleton<IExecutionContext>(
        FakeExecutionContext(tenantId: 'tenant-1', userId: 'user-1'),
      )
      ..registerSingleton<IPrincipalSnapshot>(_FakePrincipalSnapshot(
        permissions: permissions,
      ));

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/partner/detail',
          builder: (context, state) {
            final hasPermission = getIt<IPrincipalSnapshot>().hasPermission(PartnerPermissions.viewDetail);
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
            return PartnerDetailPage(
              partnerId: 'partner-1',
              initialPartner: passInitialPartner
                  ? PartnerItemModel(
                      id: 'partner-1',
                      avatarText: 'NA',
                      name: 'Nguyen Van An',
                      role: 'Khách hàng',
                      status: initialStatus,
                      phone: '0912345678',
                      email: 'an@example.com',
                      taxId: '0312345678',
                      updatedAt: '08:00 01/07/2026',
                      billingName: 'Cong ty An',
                      billingAddress: '456 Le Loi',
                      billingEmail: 'billing@example.com',
                      note: 'Khach hang uu tien',
                    )
                  : null,
            );
          },
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/partner/detail'),
                child: const Text('Go to Detail'),
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

  Future<void> navigateToDetail(WidgetTester tester) async {
    await tester.tap(find.text('Go to Detail'));
    await tester.pumpAndSettle();
  }

  testWidgets('SCN-02 & FR-03 SCN-02: detail page loads and pre-fills partner info & billing info', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        permissions: {PartnerPermissions.viewDetail, PartnerPermissions.update},
      ),
    );
    await tester.pumpAndSettle();
    await navigateToDetail(tester);

    // Verify fields are pre-filled
    expect(find.text('Nguyen Van An'), findsWidgets);
    expect(find.text('0912345678'), findsWidgets);
    expect(find.text('an@example.com'), findsWidgets);
    expect(find.text('123 Nguyen Trai'), findsWidgets);
    expect(find.text('0312345678'), findsWidgets);

    // Verify internal note is shown
    expect(find.text('Khach hang uu tien'), findsOneWidget);
  });

  testWidgets('SCN-03: blocks user without viewDetail permission and redirects to home', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(permissions: {}), // No permission
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go to Detail'));
    await tester.pumpAndSettle();

    // Should be redirected to home page
    expect(find.text('Go to Detail'), findsOneWidget);
    expect(find.byType(PartnerDetailPage), findsNothing);
  });

  testWidgets('SCN-06: fails loading shows error screen and lets user retry', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        permissions: {PartnerPermissions.viewDetail},
        shouldFailLoading: true,
        passInitialPartner: false,
      ),
    );
    await tester.pumpAndSettle();
    await navigateToDetail(tester);

    expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
    expect(find.text('Tải lại'), findsOneWidget);

    // Toggle the loading failure flag on the registered module
    final module = getIt<IPartnerModule>() as _FakePartnerModule;
    module.shouldFailLoading = false;

    await tester.tap(find.text('Tải lại'));
    await tester.pumpAndSettle();

    expect(find.text('Không thể tải dữ liệu'), findsNothing);
    expect(find.text('Nguyen Van An'), findsWidgets);
    expect(module.loadCallCount, 2);
  });

  testWidgets('FR-04 SCN-03: deleted status shows no action menu, no edit button, and red status badge', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        permissions: {
          PartnerPermissions.viewDetail,
          PartnerPermissions.update,
          PartnerPermissions.delete,
        },
        initialStatus: 'Đã xóa',
        shouldFailLoading: true,
      ),
    );
    await tester.pumpAndSettle();
    await navigateToDetail(tester);

    // Status badge text is visible
    expect(find.text('Đã xóa'), findsOneWidget);

    // Action menu is hidden (no three-dot button)
    expect(find.byIcon(Icons.more_horiz), findsNothing);

    // Edit button is hidden
    expect(find.text('Chỉnh sửa'), findsNothing);
  });

  testWidgets('FR-05 SCN-03: hides edit button if lacking update permission', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        permissions: {PartnerPermissions.viewDetail}, // viewDetail but no update
      ),
    );
    await tester.pumpAndSettle();
    await navigateToDetail(tester);

    expect(find.text('Chỉnh sửa'), findsNothing);
  });

  testWidgets('FR-05 SCN-07: hides delete menu option if partner has business data', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        permissions: {
          PartnerPermissions.viewDetail,
          PartnerPermissions.delete,
        },
        hasBusinessData: true,
      ),
    );
    await tester.pumpAndSettle();
    await navigateToDetail(tester);

    // Open action sheet
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    // Delete option is hidden because hasBusinessData is true
    expect(find.text('Xóa hồ sơ'), findsNothing);
  });

  testWidgets('FR-05 SCN-09: late permission check fails when user permission changes after load', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        permissions: {
          PartnerPermissions.viewDetail,
          PartnerPermissions.update,
          PartnerPermissions.delete,
        },
      ),
    );
    await tester.pumpAndSettle();
    await navigateToDetail(tester);

    // Revoke update permission on principal snapshot
    final principal = getIt<IPrincipalSnapshot>() as _FakePrincipalSnapshot;
    principal.permissions = {PartnerPermissions.viewDetail, PartnerPermissions.delete};

    // Tap edit button
    await tester.tap(find.text('Chỉnh sửa'));
    await tester.pumpAndSettle();

    // Verify error toast or rejection (we remain on detail page because navigation is rejected)
    expect(find.byType(PartnerDetailPage), findsOneWidget);

    // Tap more action menu
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    // Revoke delete permission
    principal.permissions = {PartnerPermissions.viewDetail};

    // Tap delete action
    await tester.tap(find.text('Xóa hồ sơ'));
    await tester.pumpAndSettle();

    // Rejection should prevent delete command from being called
    final module = getIt<IPartnerModule>() as _FakePartnerModule;
    expect(module.deleteCallCount, 0);
  });
}
