import 'dart:async';
import 'dart:io';

import 'package:erp/core/di/injection.dart';
import 'package:erp/core/router/app_router.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:erp/features/catalog/data/product_repository.dart';
import 'package:erp/features/dashboard/data/default_pair_repository.dart';
import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/data/stock/stock_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

import '../../auth/support/scripted_auth.dart';
import '../../dashboard/presentation/fake_default_pair_repository.dart';
import 'catalog_test_registry.dart';
import 'fake_catalog_backend.dart';
import 'fake_catalog_repositories.dart';
import 'fake_catalog_scenario.dart';

final _kTransparentPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

class _FakeHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();
}

class _FakeHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _FakeHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  bool get autoUncompress => true;

  @override
  set autoUncompress(bool value) {}
}

class _FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

base class CatalogSessionStore extends SessionStore {
  @override
  bool hasPermission(String code) => true;

  @override
  bool get isOwner => true;

  @override
  String? get tenantId => 'tenant-test';
}

class _CatalogFakeStockRepository extends Fake implements StockRepository {
  @override
  Future<StockDetail> loadDetail(String productId) async => StockDetail(
        asOf: DateTime(2026, 9, 17, 21, 30),
        warehouseName: 'Kho trung tâm',
        isOwner: true,
        productId: productId,
        name: 'Amoxicillin 500mg',
        code: 'SP-0001',
        uom: 'Hộp',
        isLotTracked: false,
        physical: 150,
        available: 150,
        expiredQuantity: 0,
      );
}

/// `setUp` chung cho test catalog dựng qua `appRouter` thật.
Future<void> setUpCatalogRouterTest() async {
  HttpOverrides.global = _FakeHttpOverrides();
  await getIt.reset();
  getIt
    
    ..registerSingleton<DefaultPairRepository>(FakeDefaultPairRepository())
    ..registerSingleton<StockRepository>(_CatalogFakeStockRepository());
}

Future<void> tearDownCatalogRouterTest() async {
  try {
    appRouter.go('/');
  } catch (_) {}
  await getIt.reset();
}

/// Dựng `appRouter` thật tại [location] với [scenario], [backend] hoặc [productRepository].
Future<FakeCatalogBackend> pumpCatalogApp(
  WidgetTester tester, {
  String scenario = FakeCatalogScenario.guidedCreateOk,
  FakeCatalogBackend? backend,
  ProductRepository? productRepository,
  Size size = const Size(390, 844),
  String location = '/products/items',
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

  final session = loginSession(store: CatalogSessionStore());
  session.applySignedInUser('user-1');
  if (getIt.isRegistered<SessionController>()) {
    getIt.unregister<SessionController>();
  }
  getIt.registerSingleton<SessionController>(session);

  final effectiveBackend = registerFakeCatalog(
    getIt,
    scenario: scenario,
    backend: backend,
    registerExecutionContext: false,
  );

  if (productRepository != null) {
    if (getIt.isRegistered<ProductRepository>()) {
      getIt.unregister<ProductRepository>();
    }
    getIt.registerSingleton<ProductRepository>(productRepository);
  }

  await tester.pumpWidget(
    MaterialApp.router(theme: VTheme.lightTheme, routerConfig: appRouter),
  );
  appRouter.go(location);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 200));

  return effectiveBackend;
}

/// Đường dẫn của route trên cùng (kể cả route đẩy bằng `push`).
String get catalogCurrentPath =>
    Uri.parse(appRouter.routerDelegate.currentConfiguration.last.matchedLocation).path;

int catalogSearchCalls(FakeProductRepository repo) =>
    repo.calls.where((c) => c == 'search').length;

