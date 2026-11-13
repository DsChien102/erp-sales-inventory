import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_models.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_repository.dart';
import 'package:erp/features/inventory/logic/stock_policy/stock_policy_cubit.dart';
import 'package:erp/features/inventory/logic/stock_policy/stock_policy_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStockPolicyRepository extends Mock implements StockPolicyRepository {}

void main() {
  group('StockPolicyCubit', () {
    late MockStockPolicyRepository mockRepo;
    late List<String> generatedKeys;
    late StockPolicyCubit cubit;

    final initialProducts = [
      const StockPolicyProduct(
        productId: 'p1',
        name: 'Nobivac',
        code: 'NOBI',
        uom: 'hộp',
        isLotTracked: true,
        available: 20,
        hasExpired: false,
        hasNearExpiry: false,
        threshold: 30,
        target: 80,
      ),
      const StockPolicyProduct(
        productId: 'p2',
        name: 'Oxy',
        code: 'OXY',
        uom: 'chai',
        isLotTracked: true,
        available: 15,
        hasExpired: false,
        hasNearExpiry: false,
        threshold: null,
        target: null,
      ),
    ];

    final initialSnapshot = StockPolicySnapshot(
      revision: 5,
      isOwner: true,
      nearExpiryDays: 30,
      products: initialProducts,
    );

    setUp(() {
      mockRepo = MockStockPolicyRepository();
      generatedKeys = ['key-1', 'key-2', 'key-3', 'key-4', 'key-5'];
      var keyIndex = 0;
      cubit = StockPolicyCubit(
        repository: mockRepo,
        newKey: () => generatedKeys[keyIndex++],
      );
    });

    test('load_ready', () async {
      when(() => mockRepo.load()).thenAnswer((_) async => initialSnapshot);

      await cubit.load();

      expect(cubit.state.status, StockPolicyStatus.ready);
      expect(cubit.state.snapshot?.revision, 5);
      expect(cubit.state.expiryDraft.defaultDays, '30');
      expect(cubit.state.readOnly, isFalse);
    });

    test('load_denied_on_no_permission', () async {
      when(() => mockRepo.load()).thenThrow(
        const AppException(AppErrorCode.noPermission, serverMessage: 'Denied'),
      );

      await cubit.load();

      expect(cubit.state.status, StockPolicyStatus.denied);
      expect(cubit.state.readOnly, isTrue);
    });

    test('edit_back_to_saved_value_clears_draft', () async {
      when(() => mockRepo.load()).thenAnswer((_) async => initialSnapshot);
      await cubit.load();

      cubit.editThreshold('p1', threshold: '40');
      expect(cubit.state.thresholdDrafts.containsKey('p1'), isTrue);
      expect(cubit.state.dirtyProductIds, ['p1']);

      // Edit back to saved value '30'
      cubit.editThreshold('p1', threshold: '30');
      expect(cubit.state.thresholdDrafts.containsKey('p1'), isFalse);
      expect(cubit.state.dirtyProductIds, isEmpty);
    });

    test('save_thresholds_sends_only_dirty_rows', () async {
      when(() => mockRepo.load()).thenAnswer((_) async => initialSnapshot);
      await cubit.load();

      cubit.editThreshold('p2', threshold: '20', target: '40');
      expect(cubit.state.dirtyProductIds, ['p2']);

      final updatedSnapshot = StockPolicySnapshot(
        revision: 6,
        isOwner: true,
        nearExpiryDays: 30,
        products: initialProducts,
      );

      when(
        () => mockRepo.saveThresholds(
          idempotencyKey: any(named: 'idempotencyKey'),
          expectedRevision: 5,
          changes: any(named: 'changes'),
        ),
      ).thenAnswer((_) async => 6);

      when(() => mockRepo.load()).thenAnswer((_) async => updatedSnapshot);

      await cubit.saveThresholds();

      verify(
        () => mockRepo.saveThresholds(
          idempotencyKey: 'key-1',
          expectedRevision: 5,
          changes: [
            const ThresholdChange(productId: 'p2', threshold: 20, target: 40),
          ],
        ),
      ).called(1);

      expect(cubit.state.savedRevision, 6);
      expect(cubit.state.thresholdDrafts, isEmpty);
    });

    test('save_version_conflict_enters_conflict', () async {
      when(() => mockRepo.load()).thenAnswer((_) async => initialSnapshot);
      await cubit.load();

      cubit.editThreshold('p2', threshold: '20', target: '40');

      when(
        () => mockRepo.saveThresholds(
          idempotencyKey: any(named: 'idempotencyKey'),
          expectedRevision: 5,
          changes: any(named: 'changes'),
        ),
      ).thenThrow(
        const AppException(
          InventoryErrorCode.versionConflict,
          serverMessage: 'Stale revision',
        ),
      );

      await cubit.saveThresholds();

      expect(cubit.state.status, StockPolicyStatus.conflict);
      expect(cubit.state.readOnly, isTrue);
      // Keeps drafts
      expect(cubit.state.thresholdDrafts.containsKey('p2'), isTrue);
    });

    test('retry_reuses_idempotency_key', () async {
      when(() => mockRepo.load()).thenAnswer((_) async => initialSnapshot);
      await cubit.load();

      cubit.editThreshold('p2', threshold: '20', target: '40');

      // Attempt 1: fails network
      when(
        () => mockRepo.saveThresholds(
          idempotencyKey: any(named: 'idempotencyKey'),
          expectedRevision: 5,
          changes: any(named: 'changes'),
        ),
      ).thenThrow(
        const AppException(AppErrorCode.network, serverMessage: 'Network'),
      );

      await cubit.saveThresholds();
      expect(cubit.state.saveError, isNotNull);

      // Attempt 2: retry with same draft
      when(
        () => mockRepo.saveThresholds(
          idempotencyKey: any(named: 'idempotencyKey'),
          expectedRevision: 5,
          changes: any(named: 'changes'),
        ),
      ).thenAnswer((_) async => 6);

      when(() => mockRepo.load()).thenAnswer((_) async => initialSnapshot);

      await cubit.saveThresholds();

      // Verify key-1 was used for BOTH calls
      verify(
        () => mockRepo.saveThresholds(
          idempotencyKey: 'key-1',
          expectedRevision: 5,
          changes: any(named: 'changes'),
        ),
      ).called(2);
    });

    test('changed_draft_gets_new_key', () async {
      when(() => mockRepo.load()).thenAnswer((_) async => initialSnapshot);
      await cubit.load();

      cubit.editThreshold('p2', threshold: '20', target: '40');

      when(
        () => mockRepo.saveThresholds(
          idempotencyKey: any(named: 'idempotencyKey'),
          expectedRevision: 5,
          changes: any(named: 'changes'),
        ),
      ).thenThrow(
        const AppException(AppErrorCode.network, serverMessage: 'Network'),
      );

      await cubit.saveThresholds();

      // User changes draft
      cubit.editThreshold('p2', target: '50');

      await cubit.saveThresholds();

      // Key 1 for first attempt, Key 2 for changed draft attempt
      verify(
        () => mockRepo.saveThresholds(
          idempotencyKey: 'key-1',
          expectedRevision: 5,
          changes: any(named: 'changes'),
        ),
      ).called(1);

      verify(
        () => mockRepo.saveThresholds(
          idempotencyKey: 'key-2',
          expectedRevision: 5,
          changes: any(named: 'changes'),
        ),
      ).called(1);
    });

    test('saved_successfully_clears_key_and_subsequent_save_uses_new_key', () async {
      when(() => mockRepo.load()).thenAnswer((_) async => initialSnapshot);
      await cubit.load();

      cubit.editThreshold('p2', threshold: '20', target: '40');

      when(
        () => mockRepo.saveThresholds(
          idempotencyKey: any(named: 'idempotencyKey'),
          expectedRevision: any(named: 'expectedRevision'),
          changes: any(named: 'changes'),
        ),
      ).thenAnswer((_) async => 6);

      await cubit.saveThresholds();

      // Lưu lần 1 dùng key-1
      verify(
        () => mockRepo.saveThresholds(
          idempotencyKey: 'key-1',
          expectedRevision: 5,
          changes: any(named: 'changes'),
        ),
      ).called(1);

      // Sửa lại đúng giá trị cũ (sau khi state đã update snapshot revision 6)
      cubit.editThreshold('p2', threshold: '20', target: '40');
      await cubit.saveThresholds();

      // Phải sinh key-2 mới, không dùng lại key-1
      verify(
        () => mockRepo.saveThresholds(
          idempotencyKey: 'key-2',
          expectedRevision: 5,
          changes: any(named: 'changes'),
        ),
      ).called(1);
    });

    test('save_ok_but_reload_fails_retry_reuses_same_key', () async {
      var loadCalls = 0;
      when(() => mockRepo.load()).thenAnswer((_) async {
        loadCalls++;
        // 1: cubit.load(); 2: tải lại sau lần lưu đầu (lỗi); 3: sau "Thử lại"
        if (loadCalls == 2) throw Exception('network');
        return initialSnapshot;
      });
      await cubit.load();

      when(
        () => mockRepo.saveThresholds(
          idempotencyKey: any(named: 'idempotencyKey'),
          expectedRevision: any(named: 'expectedRevision'),
          changes: any(named: 'changes'),
        ),
      ).thenAnswer((_) async => 6);

      cubit.editThreshold('p2', threshold: '20', target: '40');
      await cubit.saveThresholds();
      expect(cubit.state.saveError, isNotNull);

      // "Thử lại": cùng nội dung, snapshot cũ ⇒ phải dùng lại đúng khoá cũ.
      await cubit.saveThresholds();

      verify(
        () => mockRepo.saveThresholds(
          idempotencyKey: 'key-1',
          expectedRevision: 5,
          changes: any(named: 'changes'),
        ),
      ).called(2);
      verifyNever(
        () => mockRepo.saveThresholds(
          idempotencyKey: 'key-2',
          expectedRevision: any(named: 'expectedRevision'),
          changes: any(named: 'changes'),
        ),
      );
      expect(cubit.state.saveError, isNull);
    });

    test('save_success_sets_saved_revision_and_reloads', () async {
      when(() => mockRepo.load()).thenAnswer((_) async => initialSnapshot);
      await cubit.load();

      cubit.editDefaultDays('45');
      expect(cubit.state.expiryDirty, isTrue);

      when(
        () => mockRepo.saveNearExpiry(
          idempotencyKey: any(named: 'idempotencyKey'),
          expectedRevision: 5,
          defaultDays: 45,
          overrides: any(named: 'overrides'),
        ),
      ).thenAnswer((_) async => 6);

      when(() => mockRepo.load()).thenAnswer(
        (_) async => StockPolicySnapshot(
          revision: 6,
          isOwner: true,
          nearExpiryDays: 45,
          products: initialProducts,
        ),
      );

      await cubit.saveNearExpiry();

      expect(cubit.state.savedRevision, 6);
      expect(cubit.state.expiryDraft.defaultDays, '45');
      expect(cubit.state.expiryDirty, isFalse);

      cubit.consumeSavedRevision();
      expect(cubit.state.savedRevision, isNull);
    });

    test('switch_tab_keeps_draft', () async {
      when(() => mockRepo.load()).thenAnswer((_) async => initialSnapshot);
      await cubit.load();

      cubit.editThreshold('p1', threshold: '50');
      cubit.editDefaultDays('60');

      expect(cubit.state.thresholdDrafts.containsKey('p1'), isTrue);
      expect(cubit.state.expiryDraft.defaultDays, '60');
      expect(cubit.state.hasUnsavedChanges, isTrue);
    });

    test('add_override_copies_default_days', () async {
      when(() => mockRepo.load()).thenAnswer((_) async => initialSnapshot);
      await cubit.load();

      cubit.editDefaultDays('45');
      cubit.addOverride('p1');

      expect(cubit.state.expiryDraft.overrides.length, 1);
      expect(cubit.state.expiryDraft.overrides[0].productId, 'p1');
      expect(cubit.state.expiryDraft.overrides[0].days, '45');
    });

    test('single_retry_reuses_key', () async {
      when(() => mockRepo.load()).thenAnswer((_) async => initialSnapshot);
      await cubit.load();

      var attempts = 0;
      when(
        () => mockRepo.saveThresholds(
          idempotencyKey: any(named: 'idempotencyKey'),
          expectedRevision: 5,
          changes: any(named: 'changes'),
        ),
      ).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) {
          throw const AppException(AppErrorCode.network, serverMessage: 'Net');
        }
        return 6;
      });

      final ok1 = await cubit.saveSingle('p2', '20', '40');
      expect(ok1, isFalse);
      expect(cubit.state.saveError, isNotNull);
      expect(cubit.state.lastFailedSave, isA<FailedSingleSave>());

      await cubit.retryLastSave();
      expect(cubit.state.saveError, isNull);
      expect(cubit.state.savedRevision, 6);

      verify(
        () => mockRepo.saveThresholds(
          idempotencyKey: 'key-1',
          expectedRevision: 5,
          changes: any(named: 'changes'),
        ),
      ).called(2);
    });
  });
}
