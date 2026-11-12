import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/data/stocktake/stocktake_repository.dart';
import 'package:erp/features/inventory/presentation/stocktake/stocktake_create_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/inventory_test_surface.dart';

class _FakeStocktakeRepository extends Fake implements StocktakeRepository {
  StocktakeFormOptions options = const StocktakeFormOptions(
    allCount: 3,
    products: [
      StocktakeProductOption(
        id: 'p1',
        name: 'Oxytetracycline',
        code: 'OXY-01',
        uom: 'chai',
        lineCount: 1,
      ),
      StocktakeProductOption(
        id: 'p2',
        name: 'Tylosin 20%',
        code: 'TYL-01',
        uom: 'lọ',
        lineCount: 2,
      ),
    ],
    lots: [
      StocktakeLotOption(
        id: 'lot1',
        productId: 'p2',
        productName: 'Tylosin 20%',
        code: 'TYL-01',
        lotCode: 'TY2408',
        isExpired: true,
        uom: 'lọ',
      ),
      StocktakeLotOption(
        id: 'lot2',
        productId: 'p2',
        productName: 'Tylosin 20%',
        code: 'TYL-01',
        lotCode: 'TY2511',
        isExpired: false,
        uom: 'lọ',
      ),
    ],
    members: [
      StocktakeMember(userId: 'u1', name: 'Nguyễn Văn An'),
      StocktakeMember(userId: 'u2', name: 'Trần Thị Bình'),
    ],
    me: 'u1',
  );

  OpenStocktakeResult nextOpenResult = const OpenStocktakeResult(
    sessionId: 's1',
    code: 'KK-261112-01',
  );
  int openCalls = 0;
  final List<String> openKeys = [];
  Object? openError;

  @override
  Future<StocktakeFormOptions> formOptions() async => options;

  @override
  Future<OpenStocktakeResult> open({
    required String idempotencyKey,
    required StocktakeScopeKind kind,
    String? productId,
    String? lotId,
    required String counterUserId,
    required String reason,
  }) async {
    openCalls++;
    openKeys.add(idempotencyKey);
    if (openError != null) {
      final err = openError!;
      openError = null;
      throw err;
    }
    return nextOpenResult;
  }
}

void main() {
  late _FakeStocktakeRepository repository;

  setUp(() async {
    await GetIt.I.reset();
    repository = _FakeStocktakeRepository();
    GetIt.I.registerSingleton<StocktakeRepository>(repository);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget buildApp({
    Size size = const Size(390, 844),
    String? initialProductId,
    String? initialLotId,
    ValueChanged<String>? onOpened,
    void Function(String id, StocktakeStatus s)? onOpenConflict,
  }) {
    useInventoryTestSurface(size);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: size),
        child: child!,
      ),
      home: StocktakeCreatePage(
        initialProductId: initialProductId,
        initialLotId: initialLotId,
        onOpened: onOpened ?? (_) {},
        onOpenConflict: onOpenConflict ?? (_, _) {},
      ),
    );
  }

  group('StocktakeCreatePage', () {
    testWidgets(
      'create_ready shows 3 scopes (no Nhóm sản phẩm) and Q-5-2 banner on 390 and 1280',
      (tester) async {
        for (final size in const [Size(390, 844), Size(1280, 800)]) {
          await tester.pumpWidget(buildApp(size: size));
          await tester.pumpAndSettle();

          expect(find.text('Toàn kho'), findsWidgets);
          expect(find.text('Sản phẩm'), findsOneWidget);
          expect(find.text('Lô'), findsOneWidget);
          expect(find.text('Nhóm sản phẩm'), findsNothing);
          expect(find.text('3 mặt hàng'), findsOneWidget);
          expect(find.text('Khi mở phiên'), findsOneWidget);
          expect(
            find.textContaining('3 mặt hàng sẽ được đếm.'),
            findsOneWidget,
          );
          expect(
            find.textContaining(
              'Hàng vẫn bán, nhận bình thường; chênh lệch tính theo tồn lúc ghi nhận.',
            ),
            findsOneWidget,
          );
        }
      },
    );

    testWidgets(
      'create_validation disables footer with blocker messages when missing lot or reason',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Lô'));
        await tester.pumpAndSettle();

        expect(find.text('Chọn phạm vi cụ thể'), findsWidgets);
        final openButton = tester.widget<VButton>(
          find.widgetWithText(VButton, 'Mở phiên kiểm kê'),
        );
        expect(openButton.onPressed, isNull);

        await tester.tap(find.text('Toàn kho').first);
        await tester.pumpAndSettle();

        final reasonField = find.widgetWithText(VTextField, 'Kiểm kê định kỳ');
        await tester.enterText(reasonField, '');
        await tester.pumpAndSettle();

        expect(find.text('Nhập lý do kiểm kê'), findsWidgets);
        final disabledAfterClear = tester.widget<VButton>(
          find.widgetWithText(VButton, 'Mở phiên kiểm kê'),
        );
        expect(disabledAfterClear.onPressed, isNull);
      },
    );

    testWidgets('create_prefill_lot selects Lô and fills TY2408 with Đổi', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(initialLotId: 'lot1'));
      await tester.pumpAndSettle();

      expect(find.text('Tylosin 20% · Lô TY2408'), findsOneWidget);
      expect(find.text('Đổi'), findsOneWidget);
    });

    testWidgets('create_open_confirm opens sheet and navigates to opened id', (
      tester,
    ) async {
      String? openedId;
      await tester.pumpWidget(buildApp(onOpened: (id) => openedId = id));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(VButton, 'Mở phiên kiểm kê'));
      await tester.pumpAndSettle();

      expect(find.text('Mở phiên kiểm kê?'), findsOneWidget);
      expect(
        find.text(
          'Phiên sẽ đếm 3 mặt hàng. Hàng vẫn bán, nhận bình thường trong lúc kiểm.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(VButton, 'Mở phiên'));
      await tester.pumpAndSettle();

      expect(repository.openCalls, 1);
      expect(openedId, 's1');
    });

    testWidgets('create_conflict shows conflict banner and calls onOpenConflict', (
      tester,
    ) async {
      repository.nextOpenResult = const OpenStocktakeResult(
        conflict: StocktakeConflict(
          sessionId: 's-open',
          code: 'KK-261111-01',
          scopeLabel: 'Toàn kho',
        ),
      );
      String? conflictId;
      StocktakeStatus? conflictStatus;

      await tester.pumpWidget(
        buildApp(
          onOpenConflict: (id, status) {
            conflictId = id;
            conflictStatus = status;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(VButton, 'Mở phiên kiểm kê'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(VButton, 'Mở phiên'));
      await tester.pumpAndSettle();

      expect(find.text('Phạm vi đang có phiên khác'), findsOneWidget);
      expect(
        find.text(
          'KK-261111-01 đang kiểm Toàn kho. Mở phiên đó hoặc chọn phạm vi khác.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Mở phiên đang kiểm'));
      await tester.pumpAndSettle();

      expect(conflictId, 's-open');
      expect(conflictStatus, StocktakeStatus.counting);
    });

    testWidgets(
      'create_retry_reuses_idempotency_key keeps same key when retrying failed open',
      (tester) async {
        repository.openError = const AppException(AppErrorCode.network);
        String? openedId;

        await tester.pumpWidget(buildApp(onOpened: (id) => openedId = id));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(VButton, 'Mở phiên kiểm kê'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(VButton, 'Mở phiên'));
        await tester.pumpAndSettle();

        expect(find.text('Thử lại'), findsOneWidget);

        await tester.tap(find.widgetWithText(VButton, 'Thử lại'));
        await tester.pumpAndSettle();

        expect(repository.openCalls, 2);
        expect(repository.openKeys[0], repository.openKeys[1]);
        expect(openedId, 's1');
      },
    );

    testWidgets(
      'create_scope_sheet searches, shows empty, and selects product scope',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sản phẩm'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Chọn phạm vi cụ thể').first);
        await tester.pumpAndSettle();

        expect(find.text('Chọn phạm vi'), findsOneWidget);
        expect(find.text('Tylosin 20%'), findsOneWidget);

        await tester.enterText(find.byType(VSearchBar), 'zzz');
        await tester.pumpAndSettle();
        expect(find.text('Không tìm thấy phạm vi'), findsOneWidget);

        await tester.enterText(find.byType(VSearchBar), 'tylosin');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tylosin 20%'));
        await tester.pumpAndSettle();

        expect(find.text('Tylosin 20%'), findsOneWidget);
        expect(find.text('Đổi'), findsOneWidget);
        expect(find.textContaining('2 mặt hàng sẽ được đếm.'), findsOneWidget);
      },
    );
  });
}
