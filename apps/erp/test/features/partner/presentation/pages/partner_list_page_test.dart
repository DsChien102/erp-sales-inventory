import 'package:erp/core/di/injection.dart';
import 'package:erp/features/partner/presentation/pages/partner_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

final class _FailThenSucceedPartnerModule implements IPartnerModule {
  int callCount = 0;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    throw UnimplementedError();
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is SearchPartnersQuery) {
      callCount++;
      if (callCount == 1) {
        throw ApplicationException('Lỗi tải dữ liệu danh sách đối tác');
      }
      return PartnerSearchResultDto(
        items: [
          PartnerListItemDto(
            id: 'partner-1',
            displayName: 'Nguyen Van A',
            phone: '0912345678',
            roles: const {PartnerRole.customer},
            entityType: EntityType.individual,
            status: PartnerStatus.active,
            updatedAt: DateTime.parse('2026-07-01T00:00:00Z'),
          ),
        ],
        totalCount: 1,
      ) as TResult;
    }
    throw UnimplementedError('Unexpected query: $query');
  }
}

final class _FakePrincipalSnapshot implements IPrincipalSnapshot {
  @override
  String? get role => 'member';

  @override
  bool hasPermission(String code) => true;
}

void main() {
  setUp(() async {
    await getIt.reset();
  });

  testWidgets('SCN-07 & SCN-05: loading failure shows error view and retries successfully', (tester) async {
    final partnerModule = _FailThenSucceedPartnerModule();
    getIt
      ..registerSingleton<IPartnerModule>(partnerModule)
      ..registerSingleton<IExecutionContext>(_FakeExecutionContext())
      ..registerSingleton<IPrincipalSnapshot>(_FakePrincipalSnapshot());

    await tester.pumpWidget(
      const MaterialApp(
        home: PartnerListPage(),
      ),
    );

    // Initial load fails, pump to render failure screen
    await tester.pumpAndSettle();

    // SCN-07 check: UI must display the error message and the "Tải lại" button
    expect(find.text('Lỗi tải dữ liệu danh sách đối tác'), findsOneWidget);
    expect(find.text('Tải lại'), findsOneWidget);

    // UI must not display the empty state "Chưa có đối tác nào"
    expect(find.text('Chưa có đối tác nào'), findsNothing);

    // SCN-05 check: Tap retry ("Tải lại")
    await tester.tap(find.text('Tải lại'));
    
    // Wait for the async reload to finish
    await tester.pumpAndSettle();

    // After success, it should display the partner
    expect(find.text('Nguyen Van A'), findsOneWidget);
    expect(find.text('Lỗi tải dữ liệu danh sách đối tác'), findsNothing);
  });
}
