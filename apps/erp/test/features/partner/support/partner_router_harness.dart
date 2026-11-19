import 'package:erp/core/di/injection.dart';
import 'package:erp/core/router/app_router.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:erp/features/partner/data/models/partner_models.dart';
import 'package:erp/features/partner/data/partner_repository.dart';
import 'package:erp/features/partner/logic/partner_permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/dashboard/data/default_pair_repository.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_repository.dart';
import 'package:c45_shared_application/application.dart';
import 'package:c45_shared_testing/shared_testing.dart';

import '../../auth/support/scripted_auth.dart';
import '../../dashboard/presentation/fake_default_pair_repository.dart';
import 'fake_partner_repository.dart';

/// Phiên giả chỉ cấp đúng các quyền được truyền vào.
base class PartnerSessionStore extends SessionStore {
  PartnerSessionStore(this.granted);
  final Set<String> granted;

  @override
  bool hasPermission(String code) => granted.contains(code);

  @override
  bool get isOwner => false;

  @override
  String? get tenantId => 'tenant-test';
}

const allPartnerPermissions = {
  PartnerPermissions.view,
  PartnerPermissions.detailView,
  PartnerPermissions.create,
  PartnerPermissions.update,
  PartnerPermissions.contactManage,
  PartnerPermissions.transform,
  PartnerPermissions.statusManage,
  PartnerPermissions.delete,
  PartnerPermissions.historyView,
};

/// Chi tiết nhà cung cấp có khối chương trình NCC + lịch sử nhận hàng (G5-3):
/// trả danh sách rỗng để test Đối tác không phụ thuộc Kho.
class _EmptyGoodsReceiptRepository extends Fake implements GoodsReceiptRepository {
  @override
  Future<List<ReceiptListRow>> list({String? supplierId, int limit = 20, int offset = 0}) async => [];
}

class _EmptySupplierProgramRepository extends Fake implements SupplierProgramRepository {
  @override
  Future<List<ProgramRow>> list() async => [];
}

/// `setUp` chung cho test dựng qua `appRouter` thật.
Future<void> setUpPartnerRouterTest() async {
  await getIt.reset();
  getIt
    ..registerSingleton<IExecutionContext>(FakeExecutionContext(tenantId: 'tenant-test'))
    ..registerSingleton<DefaultPairRepository>(FakeDefaultPairRepository())
    ..registerSingleton<GoodsReceiptRepository>(_EmptyGoodsReceiptRepository())
    ..registerSingleton<SupplierProgramRepository>(_EmptySupplierProgramRepository());
}

Future<void> tearDownPartnerRouterTest() async {
  try {
    appRouter.go('/');
  } catch (_) {}
  await getIt.reset();
}

/// Dựng `appRouter` thật tại [location] với [repo] và [permissions].
Future<void> pumpPartnerApp(
  WidgetTester tester, {
  required FakePartnerRepository repo,
  Set<String> permissions = allPartnerPermissions,
  Size size = const Size(390, 844),
  String location = '/partner',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // Font Ahem của flutter_test rộng hơn font thật nên một số Row tràn vài px.
  // Các test này kiểm hành vi điều hướng, không kiểm bố cục: bỏ riêng lỗi overflow.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    previousOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = previousOnError);

  final session = loginSession(store: PartnerSessionStore(permissions));
  session.applySignedInUser('user-1');
  getIt
    ..registerSingleton<SessionController>(session)
    ..registerSingleton<PartnerRepository>(repo);

  await tester.pumpWidget(
    MaterialApp.router(theme: VTheme.lightTheme, routerConfig: appRouter),
  );
  appRouter.go(location);
  await tester.pumpAndSettle();
}

/// Đường dẫn của route trên cùng (kể cả route đẩy bằng `push`).
String get partnerCurrentPath =>
    Uri.parse(appRouter.routerDelegate.currentConfiguration.last.matchedLocation).path;

int partnerSearchCalls(FakePartnerRepository repo) => repo.calls.where((c) => c == 'search').length;

/// Hồ sơ chi tiết là tổ chức có người liên hệ, nhưng `search` trả danh sách
/// hỗn hợp (cá nhân + tổ chức): dùng cho luồng "thêm người có sẵn".
class OrganizationDetailMixedSearchRepository extends FakePartnerRepository {
  OrganizationDetailMixedSearchRepository()
    : _mixed = FakePartnerRepository(),
      super(scenario: FakePartnerScenario.detailOrganizationWithContacts);

  final FakePartnerRepository _mixed;

  @override
  Future<PartnerSearchResultDto> search({
    String? query,
    PartnerType? partnerType,
    PartnerRoleType? role,
    bool requireBothRoles = false,
    bool requireAnyRole = false,
    PartnerStatus? status,
    int? updatedWithinDays,
    int page = 1,
    int limit = 20,
    String? sort,
  }) {
    calls.add('search');
    return _mixed.search(
      query: query,
      partnerType: partnerType,
      role: role,
      status: status,
      page: page,
      limit: limit,
      sort: sort,
    );
  }
}
