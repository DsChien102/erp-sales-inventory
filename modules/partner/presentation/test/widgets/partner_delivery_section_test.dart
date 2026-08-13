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

  VCombobox<String> communeCombobox(WidgetTester tester) {
    return tester.widget<VCombobox<String>>(
      find.descendant(
        of: find.byKey(const Key('input_delivery_commune')),
        matching: find.byType(VCombobox<String>),
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
    expect(find.byType(VCombobox<String>), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const Key('input_delivery_commune')),
        matching: find.text('Nhập tỉnh / thành phố trước'),
      ),
      findsOneWidget,
    );
    expect(communeCombobox(tester).enabled, isFalse);
  });

  testWidgets('selecting province enables ward dropdown', (tester) async {
    await tester.pumpWidget(buildDeliverySection());
    await tester.runAsync(VnAdministrativeUnitsLoader.load);
    await tester.pumpAndSettle();

    final cubit =
        tester.element(find.byType(PartnerDeliverySection)).read<PartnerCreateCubit>();
    cubit.updateDeliveryProvince('Thành phố Hà Nội');
    await tester.pump();
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('input_delivery_commune')),
        matching: find.text('Nhập xã / phường'),
      ),
      findsOneWidget,
    );
    expect(communeCombobox(tester).enabled, isTrue);
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

  testWidgets('detail address uses VTextFormField', (tester) async {
    await tester.pumpWidget(buildDeliverySection());
    await tester.runAsync(VnAdministrativeUnitsLoader.load);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('input_delivery_address')),
        matching: find.byType(VTextFormField),
      ),
      findsOneWidget,
    );
  });
}
