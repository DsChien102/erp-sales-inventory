import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/testing.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_partner_presentation/src/data/vn_administrative_units_loader.dart';
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

  DropdownMenu<String> communeMenu(WidgetTester tester) {
    return tester.widget<DropdownMenu<String>>(
      find.descendant(
        of: find.byKey(const Key('input_delivery_commune')),
        matching: find.byType(DropdownMenu<String>),
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
    expect(
      find.descendant(
        of: find.byKey(const Key('input_delivery_commune')),
        matching: find.text('Chọn tỉnh / thành phố trước'),
      ),
      findsOneWidget,
    );
    expect(communeMenu(tester).enabled, isFalse);
  });

  testWidgets('province and ward dropdowns share builtin trailing layout', (
    tester,
  ) async {
    await tester.pumpWidget(buildDeliverySection());
    await tester.runAsync(VnAdministrativeUnitsLoader.load);
    await tester.pumpAndSettle();

    final province = tester.widget<VCompactSearchableDropdown<String>>(
      find.byKey(const Key('input_delivery_province')),
    );
    final ward = tester.widget<VCompactSearchableDropdown<String>>(
      find.descendant(
        of: find.byKey(const Key('input_delivery_commune')),
        matching: find.byType(VCompactSearchableDropdown<String>),
      ),
    );

    expect(province.trailingMode, VCompactDropdownTrailingMode.builtin);
    expect(ward.trailingMode, VCompactDropdownTrailingMode.builtin);
    expect(ward.stickyActionsReserve, province.stickyActionsReserve);
    expect(ward.menuHeight, province.menuHeight);

    final fieldFinder = find.byKey(const Key('input_delivery_province'));
    final menu = tester.widget<DropdownMenu<String>>(
      find.descendant(
        of: fieldFinder,
        matching: find.byType(DropdownMenu<String>),
      ),
    );
    final fieldWidth = tester.getSize(fieldFinder).width;
    expect(menu.expandedInsets, EdgeInsets.zero);
    expect(menu.menuStyle?.minimumSize?.resolve({})?.width, fieldWidth);
    expect(menu.menuStyle?.maximumSize?.resolve({})?.width, fieldWidth);
  });

  testWidgets('selecting province enables ward dropdown', (tester) async {
    await tester.pumpWidget(buildDeliverySection());
    await tester.runAsync(VnAdministrativeUnitsLoader.load);
    await tester.pumpAndSettle();

    final cubit = tester.element(find.byType(PartnerDeliverySection)).read<PartnerCreateCubit>();
    cubit.updateDeliveryProvince('Thành phố Hà Nội');
    await tester.pump();
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('input_delivery_commune')),
        matching: find.text('Chọn xã / phường'),
      ),
      findsOneWidget,
    );
    expect(communeMenu(tester).enabled, isTrue);
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
      ..updateDeliveryCommune('Phường Ba Đình');
    await tester.pumpAndSettle();

    // Collapsed display — tap to reveal DropdownMenu TextField.
    await tester.tap(find.text('Phường Ba Đình'));
    await tester.pumpAndSettle();

    final wardTextField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('input_delivery_commune')),
        matching: find.byType(TextField),
      ),
    );
    final expectedStyle = VTypography.bodyDefault;
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
    await tester.tap(communeField);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(of: communeField, matching: find.byType(TextField)),
      'dai mo',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Phường Đại Mỗ').last);
    await tester.pumpAndSettle();

    expect(find.text('Phường Đại Mỗ'), findsWidgets);
  });

  testWidgets('province and ward trailing icons share the same slot size', (
    tester,
  ) async {
    await tester.pumpWidget(buildDeliverySection());
    await tester.runAsync(VnAdministrativeUnitsLoader.load);
    await tester.pumpAndSettle();

    final cubit = tester.element(find.byType(PartnerDeliverySection)).read<PartnerCreateCubit>();
    cubit
      ..updateDeliveryProvince('Thành phố Hà Nội')
      ..updateDeliveryCommune('Phường Ba Đình');
    await tester.pumpAndSettle();

    final provinceIcons = find.descendant(
      of: find.byKey(const Key('input_delivery_province')),
      matching: find.byIcon(Icons.keyboard_arrow_down),
    );
    final wardIcons = find.descendant(
      of: find.byKey(const Key('input_delivery_commune')),
      matching: find.byIcon(Icons.keyboard_arrow_down),
    );
    expect(provinceIcons, findsOneWidget);
    expect(wardIcons, findsOneWidget);

    final provinceIconRect = tester.getRect(provinceIcons);
    final wardIconRect = tester.getRect(wardIcons);
    expect(provinceIconRect.width, wardIconRect.width);
    expect(provinceIconRect.height, wardIconRect.height);
    expect(provinceIconRect.right, moreOrLessEquals(wardIconRect.right, epsilon: 0.5));
  });
}
