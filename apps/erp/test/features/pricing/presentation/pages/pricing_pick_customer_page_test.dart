// 4-A, H19: PricingPickCustomerPage tìm khách qua module partner.
import 'package:erp/features/pricing/presentation/pages/pricing_pick_customer_page.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:erp/features/partner/data/partner_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../partner/support/scripted_partner_repository.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<ScriptedPartnerRepository> pump(
    WidgetTester tester,
    Object? Function(Map<String, Object?> args) onSearch,
  ) async {
    final module = ScriptedPartnerRepository(onCall: (_, args) => onSearch(args));
    getIt.registerSingleton<PartnerRepository>(module);
    await tester.pumpWidget(const MaterialApp(home: PricingPickCustomerPage()));
    await tester.pumpAndSettle();
    return module;
  }

  testWidgets('tìm khách: customer, requireAnyRole, đang hoạt động, limit 30', (tester) async {
    final module = await pump(
      tester,
      (_) => const PartnerSearchResultDto(
        items: [
          PartnerListItemDto(
            partnerId: 'p-1',
            displayName: 'Khách A',
            partnerType: PartnerType.person,
            status: PartnerStatus.active,
            roles: [PartnerRoleType.customer],
          ),
        ],
        page: 1,
        limit: 30,
        total: 1,
      ),
    );

    final call = module.invocations.single;
    expect(call.method, 'search');
    expect(call.args['query'], isNull);
    expect(call.args['role'], PartnerRoleType.customer);
    expect(call.args['requireAnyRole'], isTrue);
    expect(call.args['status'], PartnerStatus.active);
    expect(call.args['limit'], 30);
    expect(find.text('Khách A'), findsOneWidget);
  });

  testWidgets('lỗi tải → "Không tải được danh sách khách hàng."', (tester) async {
    await pump(
      tester,
      (_) => throw const AppException('NO_PERMISSION'),
    );

    expect(find.text('Không tải được danh sách khách hàng.'), findsOneWidget);
  });
}
