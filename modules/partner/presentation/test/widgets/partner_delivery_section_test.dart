import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_partner_presentation/src/data/vn_administrative_units_loader.dart';
import 'package:vet45_partner_presentation/src/widgets/partner_compact_field.dart';
import 'package:vet45_partner_presentation/src/widgets/partner_delivery_section.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await VnAdministrativeUnitsLoader.load();
  });

  Widget buildDeliverySection() {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => PartnerCreateCubit(
          partnerType: PartnerType.person,
          partnerModule: FakePartnerModule(),
          executionContext: FakeExecutionContext(),
        ),
        child: const Scaffold(
          body: SingleChildScrollView(
            child: PartnerDeliverySection(),
          ),
        ),
      ),
    );
  }

  testWidgets('ward dropdown stays disabled until province is selected', (
    tester,
  ) async {
    await tester.pumpWidget(buildDeliverySection());
    await tester.runAsync(VnAdministrativeUnitsLoader.load);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('input_delivery_province')), findsOneWidget);

    final communeField = find.byKey(const Key('input_delivery_commune'));
    expect(
      find.descendant(
        of: communeField,
        matching: find.text('Chọn tỉnh / thành phố trước'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<InkWell>(
            find.descendant(of: communeField, matching: find.byType(InkWell)),
          )
          .onTap,
      isNull,
    );
  });

  testWidgets('address dropdown menus match the field width and rounded shape', (
    tester,
  ) async {
    await tester.pumpWidget(buildDeliverySection());
    await tester.runAsync(VnAdministrativeUnitsLoader.load);
    await tester.pumpAndSettle();

    final fieldFinder = find.byKey(const Key('input_delivery_province'));
    final menu = tester.widget<DropdownMenu<String>>(
      find.descendant(
        of: fieldFinder,
        matching: find.byType(DropdownMenu<String>),
      ),
    );
    final fieldWidth = tester.getSize(fieldFinder).width;
    expect(menu.alignmentOffset, PartnerCompactField.menuAlignmentOffset);
    expect(menu.menuStyle?.alignment, PartnerCompactField.menuAlignment);
    expect(menu.menuStyle?.minimumSize?.resolve({})?.width, fieldWidth);
    expect(menu.menuStyle?.maximumSize?.resolve({})?.width, fieldWidth);
    final shape = menu.menuStyle?.shape?.resolve({}) as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(VRadius.input));
  });

  testWidgets('selecting province enables ward dropdown', (tester) async {
    await tester.pumpWidget(buildDeliverySection());
    await tester.runAsync(VnAdministrativeUnitsLoader.load);
    await tester.pumpAndSettle();

    final cubit = tester.element(find.byType(PartnerDeliverySection)).read<PartnerCreateCubit>();
    cubit.updateDeliveryProvince('Thành phố Hà Nội');
    await tester.pump();
    await tester.pump();

    final communeField = find.byKey(const Key('input_delivery_commune'));
    expect(
      find.descendant(of: communeField, matching: find.text('Chọn xã / phường')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<InkWell>(
            find.descendant(of: communeField, matching: find.byType(InkWell)),
          )
          .onTap,
      isNotNull,
    );
  });

  testWidgets('province and ward values use the same typography', (
    tester,
  ) async {
    await tester.pumpWidget(buildDeliverySection());
    await tester.runAsync(VnAdministrativeUnitsLoader.load);
    await tester.pumpAndSettle();

    final cubit = tester.element(find.byType(PartnerDeliverySection)).read<PartnerCreateCubit>();
    cubit
      ..updateDeliveryProvince('Thành phố Hà Nội')
      ..updateDeliveryCommune('Xã Hát Môn');
    await tester.pump();

    final wardTextField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('input_ward_inline_search')),
        matching: find.byType(TextField),
      ),
    );
    final expectedStyle = PartnerCompactField.valueStyle(
      tester.element(find.byKey(const Key('input_delivery_commune'))),
    );

    expect(wardTextField.style?.fontSize, expectedStyle.fontSize);
    expect(wardTextField.style?.fontWeight, expectedStyle.fontWeight);
  });

  testWidgets('typing in ward field opens dropdown, filters, and selects', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => PartnerCreateCubit(
            partnerType: PartnerType.person,
            partnerModule: FakePartnerModule(),
            executionContext: FakeExecutionContext(),
          )..updateDeliveryProvince('Thành phố Hà Nội'),
          child: const Scaffold(
            body: SingleChildScrollView(
              child: PartnerDeliverySection(),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(VnAdministrativeUnitsLoader.load);
    await tester.pumpAndSettle();

    final communeField = find.byKey(const Key('input_delivery_commune'));
    final wardInput = find.descendant(
      of: communeField,
      matching: find.byKey(const Key('input_ward_inline_search')),
    );
    await tester.tap(wardInput);
    await tester.enterText(
      find.descendant(of: wardInput, matching: find.byType(TextField)),
      'dai mo',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Phường Đại Mỗ'));
    await tester.pumpAndSettle();

    expect(find.text('Phường Đại Mỗ'), findsOneWidget);
  });

  testWidgets('ward arrow opens dropdown without focusing inline input', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => PartnerCreateCubit(
            partnerType: PartnerType.person,
            partnerModule: FakePartnerModule(),
            executionContext: FakeExecutionContext(),
          )..updateDeliveryProvince('Thành phố Hà Nội'),
          child: const Scaffold(
            body: SingleChildScrollView(child: PartnerDeliverySection()),
          ),
        ),
      ),
    );
    await tester.runAsync(VnAdministrativeUnitsLoader.load);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_ward_dropdown')));
    await tester.pumpAndSettle();

    expect(find.text('Phường Ba Đình'), findsOneWidget);
    final input = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('input_ward_inline_search')),
        matching: find.byType(TextField),
      ),
    );
    expect(input.focusNode?.hasFocus, isFalse);
  });
}
