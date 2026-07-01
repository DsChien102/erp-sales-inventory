import 'package:erp/core/di/injection.dart';
import 'package:erp/features/partner/presentation/pages/partner_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  setUp(() async {
    await getIt.reset();
  });

  testWidgets('detail page returns true to list after edit succeeds', (tester) async {
    final partnerModule = FakePartnerModule(scenario: FakePartnerScenario.detailRefresh);
    getIt
      ..registerSingleton<IPartnerModule>(partnerModule)
      ..registerSingleton<IExecutionContext>(
        FakeExecutionContext(tenantId: 'tenant-1', userId: 'user-1'),
      );

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
