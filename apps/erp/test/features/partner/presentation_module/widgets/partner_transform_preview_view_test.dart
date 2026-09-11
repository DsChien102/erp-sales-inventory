import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:erp/features/partner/presentation.dart';

void main() {
  final partner = PartnerDetailDto(
    partnerId: 'p-person-1',
    partnerType: PartnerType.person,
    status: PartnerStatus.active,
    displayName: 'Nguyễn Văn An',
    roles: const [PartnerRoleType.customer],
    availableActions: const [PartnerAvailableAction.transform],
    expectedVersion: 2,
    personProfile: const PersonProfileDto(
      fullName: 'Nguyễn Văn An',
      phone: '0901 234 567',
    ),
  );
  const organization = OrganizationProfileInput(
    organizationType: OrganizationType.company,
    organizationName: 'Công ty TNHH An Phát',
    shortName: 'An Phát',
    phone: '028 3822 5511',
    email: 'info@anphat.vn',
  );

  testWidgets('wgt_e01_u06_fr04_01 renders before and after from state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerTransformPreviewView(
            partner: partner,
            organization: organization,
            onBack: () {},
            onContinue: () {},
          ),
        ),
      ),
    );

    expect(find.text('Xem trước'), findsOneWidget);
    expect(find.text('Trước khi chuyển'), findsOneWidget);
    expect(find.text('Sau khi chuyển'), findsOneWidget);
    expect(find.text('Nguyễn Văn An'), findsNWidgets(2));
    expect(find.text('Công ty TNHH An Phát'), findsOneWidget);
    expect(find.text('028 3822 5511'), findsOneWidget);
    expect(
      find.text('Người liên hệ chính (từ hồ sơ cá nhân)'),
      findsOneWidget,
    );
    expect(
      find.text('Lịch sử giao dịch và dữ liệu liên quan sẽ được giữ nguyên.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('transform_preview_back')), findsOneWidget);
    expect(
      find.byKey(const Key('transform_preview_continue')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const Key('transform_preview_continue')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('wgt_e01_u06_fr04_02 emits preview actions', (tester) async {
    var backCount = 0;
    var continueCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerTransformPreviewView(
            partner: partner,
            organization: organization,
            onBack: () => backCount++,
            onContinue: () => continueCount++,
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('transform_preview_back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('transform_preview_back')));
    await tester.tap(find.byKey(const Key('transform_preview_continue')));

    expect(backCount, 1);
    expect(continueCount, 1);
  });

  testWidgets('shows server error banner on preview', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerTransformPreviewView(
            partner: partner,
            organization: organization,
            errorMessage: PartnerTransformCubit.duplicateUserMessage,
            onBack: () {},
            onContinue: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('transform_blocking_banner')), findsOneWidget);
    expect(find.text(PartnerTransformCubit.duplicateUserMessage), findsOneWidget);
    expect(find.text('Xem trước'), findsOneWidget);
  });
}
