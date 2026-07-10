import 'package:erp/features/partner/presentation/pages/partner_contacts_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_contact_form_page.dart';
import 'package:erp/features/partner/presentation/pages/partner_contact_select_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildRouter({
    required FakePartnerModule partnerModule,
    required List<String> permissions,
    String initialLocation = '/partner/p-org-1/contacts',
  }) {
    final session = IamSession()
      ..apply(
        PrincipalAccessDto(
          userId: 'user-1',
          tenantId: 'tenant-1',
          role: 'staff',
          permissions: permissions,
        ),
      );

    getIt
      ..registerSingleton<IExecutionContext>(FakeExecutionContext())
      ..registerSingleton<IPartnerModule>(partnerModule)
      ..registerSingleton<IamSession>(session);

    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/partner/:partnerId/contacts',
          builder: (context, state) {
            final partnerId = state.pathParameters['partnerId']!;
            return PartnerContactsPage(
              partnerId: partnerId,
              partnerModule: partnerModule,
              executionContext: getIt<IExecutionContext>(),
            );
          },
        ),
        GoRoute(
          path: '/partner/:partnerId/contacts/new',
          builder: (context, state) {
            final partnerId = state.pathParameters['partnerId']!;
            final contact = state.extra as PartnerContactDto?;
            return PartnerContactFormPage(
              partnerId: partnerId,
              contact: contact,
              partnerModule: partnerModule,
              executionContext: getIt<IExecutionContext>(),
            );
          },
        ),
        GoRoute(
          path: '/partner/:partnerId/contacts/select',
          builder: (context, state) {
            final partnerId = state.pathParameters['partnerId']!;
            return PartnerContactSelectPage(
              partnerId: partnerId,
              partnerModule: partnerModule,
              executionContext: getIt<IExecutionContext>(),
            );
          },
        ),
        GoRoute(
          path: '/partner/:partnerId/contacts/:contactId/edit',
          builder: (context, state) {
            final partnerId = state.pathParameters['partnerId']!;
            final contactId = state.pathParameters['contactId']!;
            final contact = state.extra as PartnerContactDto?;
            return PartnerContactFormPage(
              partnerId: partnerId,
              contactId: contactId,
              contact: contact,
              partnerModule: partnerModule,
              executionContext: getIt<IExecutionContext>(),
            );
          },
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets(
    'e2e_e01_u05: loads contacts, triggers add contact flow (create new)',
    (tester) async {
      final partnerModule = FakePartnerModule(
        scenario: FakePartnerScenario.detailOrganizationWithContacts,
      );

      await tester.pumpWidget(
        buildRouter(
          partnerModule: partnerModule,
          permissions: const [PartnerPermissions.contactManage],
        ),
      );
      await tester.pumpAndSettle();

      // Check organization context and existing contact
      expect(find.text('Công ty ABC'), findsOneWidget);
      expect(find.text('Trần Thị B'), findsOneWidget);
      expect(find.text('Kế toán'), findsOneWidget);
      expect(find.text('Chính'), findsOneWidget);

      // Tap FAB to add
      expect(find.byKey(const Key('btn_add_contact_fab')), findsOneWidget);
      await tester.tap(find.byKey(const Key('btn_add_contact_fab')));
      await tester.pumpAndSettle();

      // Expect bottom sheet with choices
      expect(find.text('Tạo người liên hệ mới'), findsOneWidget);
      expect(find.text('Chọn từ cá nhân có sẵn'), findsOneWidget);

      // Select Create New
      await tester.tap(find.text('Tạo người liên hệ mới'));
      await tester.pumpAndSettle();

      // Expect to be on Form Page
      expect(find.byKey(const Key('wgt_contact_form')), findsOneWidget);
      expect(find.text('Thêm người liên hệ'), findsOneWidget);

      // Enter input fields
      await tester.enterText(find.byKey(const Key('input_contact_fullname')), 'Nguyễn Văn An');
      await tester.enterText(find.byKey(const Key('input_contact_phone')), '0901112222');
      await tester.enterText(find.byKey(const Key('input_contact_email')), 'an@example.com');
      await tester.pumpAndSettle();

      // Select role
      await tester.tap(find.byKey(const Key('input_contact_role')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kế toán').last);
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      // Expect popped back and reloaded contacts page
      expect(find.text('Công ty ABC'), findsOneWidget);
    },
  );

  testWidgets(
    'e2e_e01_u05: taps contact row, triggers actions (remove contact)',
    (tester) async {
      final partnerModule = FakePartnerModule(
        scenario: FakePartnerScenario.detailOrganizationWithContacts,
      );

      await tester.pumpWidget(
        buildRouter(
          partnerModule: partnerModule,
          permissions: const [PartnerPermissions.contactManage],
        ),
      );
      await tester.pumpAndSettle();

      // Tap contact row
      await tester.tap(find.text('Trần Thị B'));
      await tester.pumpAndSettle();

      // Expect action sheet
      expect(find.text('Thao tác'), findsOneWidget);
      expect(find.text('Chỉnh sửa liên hệ'), findsOneWidget);
      expect(find.text('Gỡ khỏi tổ chức'), findsOneWidget);

      // Tap remove contact
      await tester.tap(find.text('Gỡ khỏi tổ chức'));
      await tester.pumpAndSettle();

      // Expect remove confirmation dialog
      expect(find.text('Gỡ người liên hệ?'), findsOneWidget);

      // Tap confirm remove
      await tester.tap(find.text('Gỡ liên hệ'));
      await tester.pumpAndSettle();

      // Dialog should close
      expect(find.text('Gỡ người liên hệ?'), findsNothing);
    },
  );
}
