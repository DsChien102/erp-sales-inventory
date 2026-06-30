import 'package:erp/core/di/injection.dart';
import 'package:erp/features/partner/presentation/pages/partner_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

final class _FakeExecutionContext implements IExecutionContext {
  @override
  String get correlationId => 'test-correlation';

  @override
  Future<String> requireTenantId() async => 'tenant-1';

  @override
  Future<String> requireUserId() async => 'user-1';
}

final class _FakePartnerModule implements IPartnerModule {
  int detailLoadCount = 0;

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    throw UnimplementedError();
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    if (query is GetPartnerDetailQuery) {
      final detailQuery = query as GetPartnerDetailQuery;
      detailLoadCount += 1;
      return PartnerDetailDto(
            id: detailQuery.partnerId,
            displayName: detailLoadCount == 1 ? 'Nguyen Van An' : 'Nguyen Van B',
            phone: '0912345678',
            roles: const {PartnerRole.customer},
            entityType: EntityType.individual,
            status: PartnerStatus.active,
            createdAt: DateTime.parse('2026-07-01T00:00:00Z'),
            updatedAt: DateTime.parse('2026-07-01T00:00:00Z'),
            version: detailLoadCount,
            createdBy: 'user-1',
            updatedBy: 'user-1',
          )
          as TResult;
    }
    throw UnimplementedError('Unexpected query: $query');
  }
}

void main() {
  setUp(() async {
    await getIt.reset();
  });

  testWidgets('detail page returns true to list after edit succeeds', (tester) async {
    final partnerModule = _FakePartnerModule();
    getIt
      ..registerSingleton<IPartnerModule>(partnerModule)
      ..registerSingleton<IExecutionContext>(_FakeExecutionContext());

    bool? listRefreshResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  listRefreshResult = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PartnerDetailPage(
                        partnerId: 'partner-1',
                        initialPartner: const PartnerItemModel(
                          id: 'partner-1',
                          avatarText: 'NA',
                          name: 'Nguyen Van An',
                          role: 'Khách hàng',
                          status: 'Đang hoạt động',
                          phone: '0912345678',
                          email: '',
                          taxId: '',
                          updatedAt: '08:00 01/07/2026',
                        ),
                        editPageBuilder: (_) => Scaffold(
                          body: TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Save edit'),
                          ),
                        ),
                        canManageStatus: false,
                        canDelete: false,
                      ),
                    ),
                  );
                },
                child: const Text('Open detail'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open detail'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chỉnh sửa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save edit'));
    await tester.pumpAndSettle();

    expect(partnerModule.detailLoadCount, 2);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(listRefreshResult, isTrue);
  });
}
