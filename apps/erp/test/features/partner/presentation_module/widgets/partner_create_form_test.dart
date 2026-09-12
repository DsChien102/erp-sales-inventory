import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:erp/features/partner/presentation.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

final class _DelayedPartnerModule implements IPartnerModule {
  final duplicateCompleter = Completer<List<PartnerDuplicateMatchDto>>();

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) async {
    return const CreatePartnerResult(partnerId: 'p-delayed') as TResult;
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) async {
    return await duplicateCompleter.future as TResult;
  }
}

void main() {
  Widget buildForm({
    required PartnerType type,
    FakePartnerScenario scenario = FakePartnerScenario.defaultMixed,
    ValueChanged<String>? onOpenExisting,
  }) {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => PartnerCreateCubit(
          partnerType: type,
          partnerModule: FakePartnerModule(scenario: scenario),
          executionContext: FakeExecutionContext(),
        ),
        child: Scaffold(
          body: PartnerCreateForm(
            onCancel: () {},
            onOpenExisting: onOpenExisting ?? (_) {},
          ),
        ),
      ),
    );
  }

  Future<void> enterValidPerson(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('role_customer')));
    await tester.tap(find.byKey(const Key('btn_next')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('input_full_name')),
      'Nguyễn Văn Minh',
    );
    await tester.enterText(
      find.byKey(const Key('input_phone')),
      '0901234567',
    );
    await tester.pumpAndSettle();
  }

  testWidgets('section header toggles expand and collapse', (tester) async {
    await tester.pumpWidget(buildForm(type: PartnerType.person));

    expect(find.text('Chọn vai trò giao dịch của hồ sơ này.'), findsOneWidget);

    await tester.tap(find.text('2. Vai trò giao dịch'));
    await tester.pump();

    expect(find.text('Chọn vai trò giao dịch của hồ sơ này.'), findsNothing);

    await tester.tap(find.text('2. Vai trò giao dịch'));
    await tester.pump();

    expect(find.text('Chọn vai trò giao dịch của hồ sơ này.'), findsOneWidget);
  });

  testWidgets('role buttons toggle independently without KH & NCC shortcut', (
    tester,
  ) async {
    await tester.pumpWidget(buildForm(type: PartnerType.organization));

    expect(find.byKey(const Key('role_both')), findsNothing);
    expect(find.text('KH & NCC'), findsNothing);

    await tester.tap(find.byKey(const Key('role_customer')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('role_supplier')));
    await tester.pump();

    final context = tester.element(find.byType(PartnerCreateForm));
    expect(
      context.read<PartnerCreateCubit>().state.roles,
      [PartnerRoleType.customer, PartnerRoleType.supplier],
    );

    await tester.tap(find.byKey(const Key('btn_next')));
    await tester.pump();
    expect(find.text('KH & NCC'), findsOneWidget);
  });

  testWidgets('next action is compact and wider', (tester) async {
    await tester.pumpWidget(buildForm(type: PartnerType.person));

    expect(
      tester.getSize(find.byKey(const Key('btn_next'))),
      const Size(112, 48),
    );
  });

  testWidgets('note section has no skip/next actions', (tester) async {
    await tester.pumpWidget(buildForm(type: PartnerType.person));

    final context = tester.element(find.byType(PartnerCreateForm));
    context.read<PartnerCreateCubit>().setActiveSection(PartnerCreateSection.note);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('input_note')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('section_note')),
        matching: find.byKey(const Key('btn_skip')),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('section_note')),
        matching: find.byKey(const Key('btn_next')),
      ),
      findsNothing,
    );
  });

  testWidgets('collapsing section preserves entered field values', (tester) async {
    await tester.pumpWidget(buildForm(type: PartnerType.person));

    await tester.tap(find.byKey(const Key('role_customer')));
    await tester.tap(find.byKey(const Key('btn_next')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('input_full_name')),
      'Nguyễn Văn Minh',
    );
    await tester.enterText(
      find.byKey(const Key('input_phone')),
      '0901234567',
    );
    await tester.pumpAndSettle();

    // Collapse then re-expand — fields remount from cubit state.
    await tester.tap(find.text('3. Thông tin cá nhân'));
    await tester.pump();
    expect(find.byKey(const Key('input_full_name')), findsNothing);

    await tester.tap(find.text('3. Thông tin cá nhân'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('input_full_name')),
              matching: find.byType(TextField),
            ),
          )
          .controller
          ?.text,
      'Nguyễn Văn Minh',
    );
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('input_phone')),
              matching: find.byType(TextField),
            ),
          )
          .controller
          ?.text,
      '0901234567',
    );

    final context = tester.element(find.byType(PartnerCreateForm));
    final state = context.read<PartnerCreateCubit>().state;
    expect(state.fullName, 'Nguyễn Văn Minh');
    expect(state.phone, '0901234567');
  });

  testWidgets('wgt_e01_u02_fr02_01: person form renders accordion sections', (
    tester,
  ) async {
    await tester.pumpWidget(buildForm(type: PartnerType.person));

    expect(find.text('1. Loại hồ sơ'), findsOneWidget);
    expect(find.text('Cá nhân'), findsWidgets);
    expect(find.text('2. Vai trò giao dịch'), findsOneWidget);
    expect(find.text('3. Thông tin cá nhân'), findsOneWidget);
    expect(find.textContaining('Hóa đơn / thuế'), findsOneWidget);
    expect(find.textContaining('Địa chỉ giao hàng'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.textContaining('Ghi chú'), findsOneWidget);
    expect(find.text('Lưu & Xem'), findsOneWidget);
  });

  testWidgets('titles are free-text fields', (tester) async {
    await tester.pumpWidget(buildForm(type: PartnerType.person));
    await tester.tap(find.byKey(const Key('role_customer')));
    await tester.tap(find.byKey(const Key('btn_next')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('input_person_title')),
        matching: find.byType(EditableText),
      ),
      'Giáo sư',
    );
    await tester.pump();

    final personCubit = tester.element(find.byType(PartnerCreateForm)).read<PartnerCreateCubit>();
    expect(personCubit.state.personTitle, 'Giáo sư');
  });

  testWidgets('person phone fields reject invalid characters and accept digits with spaces', (tester) async {
    await tester.pumpWidget(buildForm(type: PartnerType.person));
    await tester.tap(find.byKey(const Key('role_customer')));
    await tester.tap(find.byKey(const Key('btn_next')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('input_phone')),
      '09ab 1+-2',
    );
    final state = tester.element(find.byType(PartnerCreateForm)).read<PartnerCreateCubit>().state;
    expect(state.phone, '');

    await tester.enterText(
      find.byKey(const Key('input_phone')),
      '090 123 4567',
    );
    await tester.enterText(
      find.byKey(const Key('input_secondary_phone')),
      '088 345 6789',
    );
    await tester.pump();

    final nextState = tester.element(find.byType(PartnerCreateForm)).read<PartnerCreateCubit>().state;
    expect(nextState.phone, '090 123 4567');
    expect(nextState.secondaryPhone, '088 345 6789');
  });

  testWidgets('organization and contact phone fields reject invalid characters and accept digits with spaces', (
    tester,
  ) async {
    await tester.pumpWidget(buildForm(type: PartnerType.organization));
    await tester.tap(find.byKey(const Key('role_customer')));
    await tester.tap(find.byKey(const Key('btn_next')));
    await tester.pumpAndSettle();

    // Invalid characters are rejected entirely by VPhoneField formatter
    await tester.enterText(find.byKey(const Key('input_phone')), '02a8-12');
    final cubit = tester.element(find.byType(PartnerCreateForm)).read<PartnerCreateCubit>();
    expect(cubit.state.phone, '');

    await tester.enterText(find.byKey(const Key('input_phone')), '028 123 4567');

    cubit.setPrimaryContactEnabled(true);
    cubit.setActiveSection(PartnerCreateSection.primaryContact);
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('input_primary_contact_phone')),
      '09a0 12',
    );
    expect(cubit.state.primaryContactPhone, '');

    await tester.enterText(
      find.byKey(const Key('input_primary_contact_phone')),
      '090 123 4567',
    );
    await tester.enterText(
      find.byKey(const Key('input_primary_contact_secondary_phone')),
      '088 345 6789',
    );
    await tester.pump();

    final state = cubit.state;
    expect(state.phone, '028 123 4567');
    expect(state.primaryContactPhone, '090 123 4567');
    expect(state.primaryContactSecondaryPhone, '088 345 6789');
  });

  testWidgets('tax code accepts digits only', (tester) async {
    await tester.pumpWidget(buildForm(type: PartnerType.organization));
    final cubit = tester.element(find.byType(PartnerCreateForm)).read<PartnerCreateCubit>();
    cubit.setActiveSection(PartnerCreateSection.invoice);
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('input_tax_code')),
      '01A0 12-34.56',
    );
    await tester.pump();

    expect(cubit.state.taxCode, '010123456');
  });

  testWidgets('wgt_e01_u02_fr04_01: invalid submit opens inline errors', (
    tester,
  ) async {
    await tester.pumpWidget(buildForm(type: PartnerType.person));

    await tester.tap(find.byKey(const Key('btn_next')));
    await tester.pump();
    expect(find.text('Vui lòng chọn vai trò giao dịch'), findsOneWidget);

    await tester.tap(find.byKey(const Key('role_customer')));
    await tester.tap(find.byKey(const Key('btn_next')));
    await tester.pump();

    expect(
      tester.widget<VButton>(find.byKey(const Key('btn_save_view'))).onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const Key('input_full_name')),
      'Nguyễn Văn Minh',
    );
    await tester.enterText(
      find.byKey(const Key('input_phone')),
      '0901234567',
    );
    await tester.enterText(
      find.byKey(const Key('input_email')),
      'invalid-email',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_save_view')));
    await tester.pump();

    expect(find.text('Email không hợp lệ'), findsOneWidget);
    final context = tester.element(find.byType(PartnerCreateForm));
    final state = context.read<PartnerCreateCubit>().state;
    expect(state.errors['email'], 'Email không hợp lệ');
  });

  testWidgets('wgt_e01_u02_fr05_01: organization includes optional contact', (
    tester,
  ) async {
    await tester.pumpWidget(buildForm(type: PartnerType.organization));

    expect(find.text('3. Thông tin tổ chức'), findsOneWidget);
    expect(find.text('4. Người liên hệ chính'), findsOneWidget);
    await tester.tap(find.byKey(const Key('section_primary_contact')));
    await tester.pump();
    await tester.tap(find.text('Thêm người liên hệ chính'));
    await tester.pump();

    expect(find.byKey(const Key('input_primary_contact_name')), findsOneWidget);
    expect(find.byKey(const Key('input_primary_contact_phone')), findsOneWidget);
    expect(find.text('Họ và tên'), findsOneWidget);
    expect(find.text('SĐT chính'), findsOneWidget);
    expect(find.text(' *'), findsWidgets);
  });

  testWidgets(
    'wgt_e01_u02_fr02_02: organization type is a three-option dropdown',
    (tester) async {
      await tester.pumpWidget(buildForm(type: PartnerType.organization));

      await tester.tap(find.byKey(const Key('role_customer')));
      await tester.tap(find.byKey(const Key('btn_next')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('input_organization_type')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('input_organization_type')),
          matching: find.byType(VSelect<String>),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('input_organization_type')));
      await tester.pumpAndSettle();

      expect(find.text('Công ty'), findsWidgets);
      expect(find.text('Hộ kinh doanh'), findsOneWidget);
      expect(find.text('Khác'), findsOneWidget);

      await tester.tap(find.text('Công ty').last);
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(PartnerCreateForm));
      expect(
        context.read<PartnerCreateCubit>().state.organizationTypeLabel,
        'Công ty',
      );
    },
  );

  testWidgets('wgt_e01_u02_fr06_01: possible duplicate allows continue', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildForm(
        type: PartnerType.person,
        scenario: FakePartnerScenario.createDupWarning,
      ),
    );
    await enterValidPerson(tester);

    await tester.tap(find.byKey(const Key('btn_save_view')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('duplicate_possible')), findsOneWidget);
    expect(find.text('Có thể là hồ sơ trùng'), findsOneWidget);
    expect(find.text('Tiếp tục tạo mới'), findsOneWidget);
    expect(find.byKey(const Key('btn_view_duplicate_detail')), findsOneWidget);
    expect(find.text('SĐT: 0901234567'), findsOneWidget);
    expect(find.byKey(const Key('btn_back_from_duplicate')), findsNothing);

    await tester.tap(find.byKey(const Key('btn_continue_create')));
    await tester.pumpAndSettle();
    expect(
      tester.widgetList(find.byType(PartnerCreateForm)),
      isNotEmpty,
    );
  });

  testWidgets('wgt_e01_u02_fr06_02: exact duplicate cannot continue', (
    tester,
  ) async {
    var openedPartnerId = '';
    await tester.pumpWidget(
      buildForm(
        type: PartnerType.person,
        scenario: FakePartnerScenario.createExactDuplicate,
        onOpenExisting: (id) => openedPartnerId = id,
      ),
    );
    await enterValidPerson(tester);

    await tester.tap(find.byKey(const Key('btn_save_view')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('duplicate_exact')), findsOneWidget);
    expect(find.text('Trùng khớp hoàn toàn'), findsOneWidget);
    expect(find.byKey(const Key('btn_continue_create')), findsNothing);
    expect(find.byKey(const Key('btn_view_duplicate_detail')), findsNothing);
    expect(find.byKey(const Key('btn_back_from_duplicate')), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_open_duplicate')));
    await tester.pumpAndSettle();
    expect(openedPartnerId, 'p-dup-1');
  });

  testWidgets('submitting disables and loads the primary action', (tester) async {
    final module = _DelayedPartnerModule();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => PartnerCreateCubit(
            partnerType: PartnerType.person,
            partnerModule: module,
            executionContext: FakeExecutionContext(),
          ),
          child: Scaffold(
            body: PartnerCreateForm(
              onCancel: () {},
              onOpenExisting: (_) {},
            ),
          ),
        ),
      ),
    );
    await enterValidPerson(tester);

    await tester.tap(find.byKey(const Key('btn_save_view')));
    await tester.pump();

    final button = tester.widget<VButton>(
      find.byKey(const Key('btn_save_view')),
    );
    expect(button.isLoading, isTrue);
    expect(button.onPressed, isNull);

    module.duplicateCompleter.complete(const []);
    await tester.pumpAndSettle();
  });

  testWidgets('permission denial removes save action and shows blocked copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildForm(
        type: PartnerType.person,
        scenario: FakePartnerScenario.createPermissionDenied,
      ),
    );
    await enterValidPerson(tester);

    await tester.tap(find.byKey(const Key('btn_save_view')));
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa có quyền tạo KH & NCC.'), findsOneWidget);
    final button = tester.widget<VButton>(
      find.byKey(const Key('btn_save_view')),
    );
    expect(button.onPressed, isNull);
  });
}
