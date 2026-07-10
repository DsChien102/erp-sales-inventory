import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
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
  });

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
