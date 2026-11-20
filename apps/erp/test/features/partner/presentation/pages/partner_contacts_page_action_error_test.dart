import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:erp/features/partner/presentation/pages/partner_contacts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/scripted_partner_repository.dart';

/// G9 (TH-03 5.1): lỗi thao tác người liên hệ phải hiện toast, không bị nuốt.
void main() {
  const fallback = 'Không thể cập nhật người liên hệ. Vui lòng thử lại.';

  final org = PartnerDetailDto(
    partnerId: 'p-org-1',
    partnerType: PartnerType.organization,
    status: PartnerStatus.active,
    displayName: 'Công ty ABC',
    roles: const [PartnerRoleType.customer],
    availableActions: const [PartnerAvailableAction.manageContacts],
    expectedVersion: 1,
    organizationProfile: const OrganizationProfileDto(
      organizationType: OrganizationType.company,
      organizationName: 'Công ty ABC',
      phone: '0901234567',
    ),
    contacts: const [
      PartnerContactDto(
        personPartnerId: 'p-c-1',
        displayName: 'Trần Thị B',
        isPrimary: true,
      ),
      PartnerContactDto(
        personPartnerId: 'p-c-2',
        displayName: 'Lê Văn C',
        isPrimary: false,
      ),
    ],
  );

  Future<void> setPrimaryViaUi(WidgetTester tester) async {
    await tester.tap(find.text('Lê Văn C'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt làm chính'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận đổi'));
    await tester.pumpAndSettle();
  }

  Future<void> pumpPage(
    WidgetTester tester,
    ScriptedPartnerRepository repository,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PartnerContactsPage(partnerId: 'p-org-1', repository: repository),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('set-primary failure shows the fallback toast, no success toast', (
    tester,
  ) async {
    final repo = ScriptedPartnerRepository(
      onCall: (method, _) => switch (method) {
        'getDetail' => org,
        'updateContact' => throw const AppException('X_UNKNOWN'),
        _ => null,
      },
    );
    await pumpPage(tester, repo);

    await setPrimaryViaUi(tester);

    expect(find.text(fallback), findsOneWidget);
    expect(find.text('Đã đặt người liên hệ chính'), findsNothing);
  });

  testWidgets('the same error repeated a second time shows the toast again', (
    tester,
  ) async {
    final repo = ScriptedPartnerRepository(
      onCall: (method, _) => switch (method) {
        'getDetail' => org,
        'updateContact' => throw const AppException('X_UNKNOWN'),
        _ => null,
      },
    );
    await pumpPage(tester, repo);

    await setPrimaryViaUi(tester);
    expect(find.text(fallback), findsOneWidget);

    // Toast đầu tự tắt rồi thử lại: cùng một câu lỗi vẫn phải hiện lại.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text(fallback), findsNothing);

    await setPrimaryViaUi(tester);
    expect(find.text(fallback), findsOneWidget);
    expect(repo.callsOf('updateContact'), hasLength(2));
  });

  testWidgets('set-primary success shows only the success toast', (
    tester,
  ) async {
    final repo = ScriptedPartnerRepository(
      onCall: (method, _) => method == 'getDetail' ? org : null,
    );
    await pumpPage(tester, repo);

    await setPrimaryViaUi(tester);

    expect(find.text('Đã đặt người liên hệ chính'), findsOneWidget);
    expect(find.text(fallback), findsNothing);
  });
}
