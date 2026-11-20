import 'package:erp/core/session/models/session_principal.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:erp/features/partner/logic/partner_permissions.dart';
import 'package:erp/features/partner/presentation/pages/partner_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../core/session/fake_session_repository.dart';
import '../support/scripted_partner_repository.dart';

PartnerDetailDto _dto({
  required bool isSystem,
  required List<PartnerRoleType> roles,
}) {
  return PartnerDetailDto(
    partnerId: 'p-1',
    partnerType: PartnerType.organization,
    status: PartnerStatus.active,
    displayName: isSystem ? 'Mua lẻ / khác' : 'Công ty ABC',
    roles: roles,
    availableActions: isSystem
        ? const [PartnerAvailableAction.viewHistory]
        : const [
            PartnerAvailableAction.update,
            PartnerAvailableAction.deactivate,
            PartnerAvailableAction.viewHistory,
          ],
    expectedVersion: 1,
    isSystem: isSystem,
    organizationProfile: const OrganizationProfileDto(
      organizationType: OrganizationType.other,
      organizationName: 'Công ty ABC',
      phone: '0901234567',
      taxCode: '0312345678',
      invoice: InvoiceProfileInput(
        invoiceName: 'Công ty ABC',
        invoiceAddress: '1 Lê Lợi',
        invoiceEmail: 'a@abc.vn',
      ),
    ),
  );
}

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
    final session = SessionStore()
      ..apply(
        const SessionPrincipal(
          userId: 'user-1',
          tenantId: 'tenant-1',
          role: 'staff',
          isOwner: false,
          permissions: [PartnerPermissions.detailView],
        ),
      );
    getIt.registerSingleton<SessionController>(
      SessionController(repository: FakeSessionRepository(), store: session),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<int> pump(
    WidgetTester tester,
    PartnerDetailDto dto,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var calls = 0;
    final repo = ScriptedPartnerRepository(
      onCall: (method, args) => method == 'getDetail' ? dto : null,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PartnerDetailPage(
          partnerId: 'p-1',
          repository: repo,
          supplierSection: (context, d) {
            calls++;
            return const Text('SECTION_SUPPLIER');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return calls;
  }

  testWidgets('system_partner_detail_no_actions_390', (tester) async {
    final calls = await pump(
      tester,
      _dto(isSystem: true, roles: const [PartnerRoleType.supplier]),
    );
    expect(find.text('Chỉnh sửa'), findsNothing);
    expect(find.text('Thao tác'), findsNothing);
    expect(
      find.text(
        'Đối tác hệ thống, dùng cho phiếu nhận mua lẻ. Không sửa hoặc xoá được.',
      ),
      findsOneWidget,
    );
    expect(find.text('SECTION_SUPPLIER'), findsNothing);
    expect(calls, 0);
  });

  testWidgets('supplier_section_shown_for_supplier', (tester) async {
    await pump(
      tester,
      _dto(isSystem: false, roles: const [PartnerRoleType.supplier]),
    );
    await tester.scrollUntilVisible(
      find.text('SECTION_SUPPLIER'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('SECTION_SUPPLIER'), findsOneWidget);
    expect(find.text('Chỉnh sửa'), findsOneWidget);
  });

  testWidgets('supplier_section_hidden_for_customer', (tester) async {
    await pump(
      tester,
      _dto(isSystem: false, roles: const [PartnerRoleType.customer]),
    );
    expect(find.text('SECTION_SUPPLIER', skipOffstage: false), findsNothing);
  });
}
