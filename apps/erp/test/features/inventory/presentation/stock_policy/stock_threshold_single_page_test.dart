import 'package:erp/core/di/injection.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_models.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_repository.dart';
import 'package:erp/features/inventory/presentation/stock_policy/stock_threshold_single_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:c45_design_system/design_system.dart';

class MockStockPolicyRepository extends Mock implements StockPolicyRepository {}

void main() {
  late MockStockPolicyRepository mockRepo;

  final sampleProduct = const StockPolicyProduct(
    productId: 'p_oxy',
    name: 'Oxytetracycline LA',
    code: 'OXY',
    uom: 'chai',
    isLotTracked: true,
    available: 25,
    hasExpired: false,
    hasNearExpiry: false,
    threshold: null,
    target: null,
  );

  StockPolicySnapshot defaultSnapshot({bool isOwner = true}) {
    return StockPolicySnapshot(
      revision: 5,
      isOwner: isOwner,
      nearExpiryDays: null,
      products: [sampleProduct],
    );
  }

  setUp(() {
    mockRepo = MockStockPolicyRepository();
    if (getIt.isRegistered<StockPolicyRepository>()) {
      getIt.unregister<StockPolicyRepository>();
    }
    getIt.registerSingleton<StockPolicyRepository>(mockRepo);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildScreen({bool isOwner = true}) {
    return MaterialApp(
      home: StockThresholdSinglePage(productId: 'p_oxy'),
    );
  }

  group('StockThresholdSinglePage', () {
    testWidgets('single_preview_hidden_when_empty', (tester) async {
      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot());

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Khả dụng 25 chai'), findsOneWidget);
      expect(find.textContaining('Sau khi lưu:'), findsNothing);

      final saveBtn = tester.widget<VButton>(
        find.widgetWithText(VButton, 'Lưu'),
      );
      expect(saveBtn.onPressed, isNull);
    });

    testWidgets('single_preview_shows_low', (tester) async {
      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot());

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Available is 25. If threshold is 30, available <= threshold -> Tồn thấp!
      await tester.enterText(
        find.bySemanticsLabel('Ngưỡng cảnh báo — Oxytetracycline LA'),
        '30',
      );
      await tester.enterText(
        find.bySemanticsLabel('Mức tồn mục tiêu — Oxytetracycline LA'),
        '60',
      );
      await tester.pumpAndSettle();

      expect(find.text('Sau khi lưu: Tồn thấp'), findsOneWidget);

      final saveBtn = tester.widget<VButton>(
        find.widgetWithText(VButton, 'Lưu'),
      );
      expect(saveBtn.onPressed, isNotNull);
    });

    testWidgets('single_save_pops_true', (tester) async {
      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot());
      when(
        () => mockRepo.saveThresholds(
          idempotencyKey: any(named: 'idempotencyKey'),
          expectedRevision: any(named: 'expectedRevision'),
          changes: any(named: 'changes'),
        ),
      ).thenAnswer((_) async => 6);

      bool? poppedResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  poppedResult = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const StockThresholdSinglePage(productId: 'p_oxy'),
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsLabel('Ngưỡng cảnh báo — Oxytetracycline LA'),
        '20',
      );
      await tester.enterText(
        find.bySemanticsLabel('Mức tồn mục tiêu — Oxytetracycline LA'),
        '40',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(VButton, 'Lưu'));
      await tester.pumpAndSettle();

      expect(poppedResult, isTrue);
    });

    testWidgets('single_staff_read_only', (tester) async {
      when(() => mockRepo.load()).thenAnswer((_) async => defaultSnapshot(isOwner: false));

      await tester.pumpWidget(buildScreen(isOwner: false));
      await tester.pumpAndSettle();

      expect(
        find.text('Chỉ chủ cửa hàng thay đổi được chính sách.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(VButton, 'Lưu'), findsNothing);
    });
  });
}

