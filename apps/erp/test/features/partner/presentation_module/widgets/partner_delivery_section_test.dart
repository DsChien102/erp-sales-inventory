import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import '../../support/fake_partner_repository.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:erp/features/partner/presentation.dart';
import 'package:erp/features/partner/presentation/data/vn_administrative_units_loader.dart';
import 'package:erp/features/partner/presentation/widgets/partner_delivery_section.dart';

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
          repository: FakePartnerRepository(),
        ),
        child: const Scaffold(
          body: SingleChildScrollView(
            child: PartnerDeliverySection(),
          ),
        ),
      ),
    );
  }

  testWidgets('ward field stays disabled until province is selected', (
    tester,
  ) async {
    await tester.pumpWidget(buildDeliverySection());
    await tester.runAsync(VnAdministrativeUnitsLoader.load);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('input_delivery_province')), findsOneWidget);
    expect(find.text('Chọn tỉnh / thành phố'), findsOneWidget);
    expect(find.text('Chọn tỉnh / thành phố trước'), findsOneWidget);
  });

  testWidgets('selecting province enables ward field', (tester) async {
    await tester.pumpWidget(buildDeliverySection());
    await tester.runAsync(VnAdministrativeUnitsLoader.load);
    await tester.pumpAndSettle();

    final cubit = tester.element(find.byType(PartnerDeliverySection)).read<PartnerCreateCubit>();
    cubit.updateDeliveryProvince('Thành phố Hà Nội');
    await tester.pump();
    await tester.pump();

    expect(find.text('Thành phố Hà Nội'), findsOneWidget);
    expect(find.text('Chọn xã / phường'), findsOneWidget);
  });

  testWidgets('tapping ward field opens picker sheet, filters, and selects', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => PartnerCreateCubit(
            partnerType: PartnerType.person,
            repository: FakePartnerRepository(),
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

    // Sheet should be open with ward list
    expect(find.byKey(const Key('list_wards')), findsOneWidget);

    final searchInput = find.byKey(const Key('input_unit_search'));
    await tester.enterText(searchInput, 'dai mo');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Phường Đại Mỗ').last);
    await tester.pumpAndSettle();

    expect(find.text('Phường Đại Mỗ'), findsOneWidget);
  });

  testWidgets('clearing province resets both province and commune', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) =>
              PartnerCreateCubit(
                  partnerType: PartnerType.person,
                  repository: FakePartnerRepository(),
                )
                ..updateDeliveryProvince('Thành phố Hà Nội')
                ..updateDeliveryCommune('Xã Hát Môn'),
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

    expect(find.text('Thành phố Hà Nội'), findsOneWidget);
    expect(find.text('Xã Hát Môn'), findsOneWidget);

    await tester.tap(find.byKey(const Key('input_delivery_province_clear')));
    await tester.pumpAndSettle();

    expect(find.text('Chọn tỉnh / thành phố'), findsOneWidget);
    expect(find.text('Chọn tỉnh / thành phố trước'), findsOneWidget);
  });

  testWidgets('detail address uses VTextArea', (tester) async {
    await tester.pumpWidget(buildDeliverySection());
    await tester.runAsync(VnAdministrativeUnitsLoader.load);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('input_delivery_address')),
        matching: find.byType(VTextArea),
      ),
      findsOneWidget,
    );
  });
}
