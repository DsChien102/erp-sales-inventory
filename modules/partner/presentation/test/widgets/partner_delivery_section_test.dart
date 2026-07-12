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
import 'package:vet45_shared_application/application.dart';
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

  List<DropdownMenu<String>> communeAndProvinceMenus(WidgetTester tester) {
    return tester.widgetList<DropdownMenu<String>>(find.byType(DropdownMenu<String>)).toList();
  }

  testWidgets('ward dropdown stays disabled until province is selected', (
    tester,
  ) async {
    await tester.pumpWidget(buildDeliverySection());
    await tester.runAsync(VnAdministrativeUnitsLoader.load);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('input_delivery_province')), findsOneWidget);

    final menus = communeAndProvinceMenus(tester);
    expect(menus, hasLength(2));
    expect(menus[1].enabled, isFalse);
    expect(menus[1].hintText, 'Chọn tỉnh / thành phố trước');
  });

  testWidgets('address dropdown menus match the field width and rounded shape', (
    tester,
  ) async {
    await tester.pumpWidget(buildDeliverySection());
    await tester.runAsync(VnAdministrativeUnitsLoader.load);
    await tester.pumpAndSettle();

    for (final fieldKey in const [
      Key('input_delivery_province'),
      Key('input_delivery_commune'),
    ]) {
      final fieldFinder = find.byKey(fieldKey);
      final menu = tester.widget<DropdownMenu<String>>(
        find.descendant(
          of: fieldFinder,
          matching: find.byType(DropdownMenu<String>),
        ),
      );
      final fieldWidth = tester.getSize(fieldFinder).width;
      expect(
        menu.alignmentOffset,
        PartnerCompactField.menuAlignmentOffset,
      );
      expect(menu.menuStyle?.alignment, PartnerCompactField.menuAlignment);
      expect(menu.menuStyle?.minimumSize?.resolve({})?.width, fieldWidth);
      expect(menu.menuStyle?.maximumSize?.resolve({})?.width, fieldWidth);
      final shape = menu.menuStyle?.shape?.resolve({}) as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(VRadius.input));
    }
  });

  testWidgets('selecting province enables ward dropdown', (tester) async {
    await tester.pumpWidget(buildDeliverySection());
    await tester.runAsync(VnAdministrativeUnitsLoader.load);
    await tester.pumpAndSettle();

    final cubit = tester.element(find.byType(PartnerDeliverySection)).read<PartnerCreateCubit>();
    cubit.updateDeliveryProvince('Thành phố Hà Nội');
    await tester.pump();
    await tester.pump();

    final communeMenu = tester.widget<DropdownMenu<String>>(
      find.descendant(
        of: find.byKey(const Key('input_delivery_commune')),
        matching: find.byType(DropdownMenu<String>),
      ),
    );
    expect(communeMenu.enabled, isTrue);
    expect(communeMenu.hintText, 'Chọn xã / phường');
    expect(communeMenu.dropdownMenuEntries.length, greaterThan(0));
  });
}
