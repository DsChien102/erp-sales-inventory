import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/idempotency_key.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_models.dart';
import 'package:erp/features/inventory/data/stock_policy/stock_policy_repository.dart';
import 'package:erp/features/inventory/logic/stock_policy/stock_policy_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StockPolicyCubit extends Cubit<StockPolicyState> {
  final StockPolicyRepository _repository;
  final String Function() _newKey;

  String? _lastThresholdPayload;
  String? _lastThresholdKey;

  String? _lastSinglePayload;
  String? _lastSingleKey;

  String? _lastExpiryPayload;
  String? _lastExpiryKey;

  StockPolicyCubit({
    required StockPolicyRepository repository,
    String Function() newKey = newIdempotencyKey,
  })  : _repository = repository,
        _newKey = newKey,
        super(const StockPolicyState());

  /// Tải thông tin chính sách và danh sách sản phẩm.
  Future<void> load() async {
    emit(state.copyWith(status: StockPolicyStatus.loading));
    try {
      final snapshot = await _repository.load();
      final defaultDays = snapshot.nearExpiryDays?.toString() ?? '';
      final overrides = snapshot.products
          .where((p) => p.nearExpiryDaysOverride != null)
          .map(
            (p) => ExpiryOverrideDraft(
              productId: p.productId,
              days: p.nearExpiryDaysOverride.toString(),
            ),
          )
          .toList();

      emit(
        state.copyWith(
          status: StockPolicyStatus.ready,
          snapshot: snapshot,
          thresholdDrafts: const {},
          expiryDraft: ExpiryDraft(
            defaultDays: defaultDays,
            overrides: overrides,
          ),
          clearSaveError: true,
        ),
      );
    } catch (e) {
      final appEx = AppException.from(e);
      if (appEx.isNoPermission || appEx.code == InventoryErrorCode.permissionDenied) {
        emit(state.copyWith(status: StockPolicyStatus.denied));
      } else {
        emit(
          state.copyWith(
            status: StockPolicyStatus.loadError,
            saveError: appEx,
          ),
        );
      }
    }
  }

  /// Tải lại, bỏ mọi nháp chưa lưu (dùng khi xung đột dữ liệu hoặc bấm "Tải lại").
  Future<void> reload() async {
    _lastThresholdPayload = null;
    _lastThresholdKey = null;
    _lastSinglePayload = null;
    _lastSingleKey = null;
    _lastExpiryPayload = null;
    _lastExpiryKey = null;
    emit(const StockPolicyState(status: StockPolicyStatus.loading));
    await load();
  }

  /// Lọc danh sách: Tất cả / Chưa có ngưỡng.
  void setFilter(ThresholdFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  /// Sửa nháp ngưỡng cảnh báo / mức tồn mục tiêu của sản phẩm.
  /// Nếu trùng với giá trị đã lưu thì xoá khỏi danh sách nháp.
  void editThreshold(
    String productId, {
    String? threshold,
    String? target,
  }) {
    final product = state.snapshot?.products
        .where((p) => p.productId == productId)
        .firstOrNull;
    if (product == null) return;

    final savedT = product.threshold?.toString() ?? '';
    final savedG = product.target?.toString() ?? '';

    final curDraft = state.thresholdDrafts[productId];
    final curT = curDraft?.threshold ?? savedT;
    final curG = curDraft?.target ?? savedG;

    final newT = threshold ?? curT;
    final newG = target ?? curG;

    final newDrafts = Map<String, ThresholdDraft>.from(state.thresholdDrafts);
    if (newT.trim() == savedT.trim() && newG.trim() == savedG.trim()) {
      newDrafts.remove(productId);
    } else {
      newDrafts[productId] = ThresholdDraft(threshold: newT, target: newG);
    }

    emit(
      state.copyWith(
        thresholdDrafts: newDrafts,
        clearSaveError: true,
      ),
    );
  }

  /// Huỷ mọi thay đổi nháp ở tab ngưỡng tồn.
  void discardThresholds() {
    emit(
      state.copyWith(
        thresholdDrafts: const {},
        clearSaveError: true,
      ),
    );
  }

  /// Lưu toàn bộ thay đổi ở tab ngưỡng tồn.
  Future<void> saveThresholds() async {
    if (state.dirtyProductIds.isEmpty ||
        state.hasThresholdError ||
        state.saving ||
        state.readOnly ||
        state.snapshot == null) {
      return;
    }

    emit(state.copyWith(saving: true, clearSaveError: true));

    final changes = state.dirtyProductIds.map((id) {
      final d = state.thresholdDrafts[id]!;
      return ThresholdChange(
        productId: id,
        threshold: int.parse(d.threshold.trim()),
        target: int.parse(d.target.trim()),
      );
    }).toList();

    final payload = changes
        .map((c) => '${c.productId}:${c.threshold}:${c.target}')
        .join(';');

    if (_lastThresholdPayload != payload || _lastThresholdKey == null) {
      _lastThresholdPayload = payload;
      _lastThresholdKey = _newKey();
    }

    try {
      final rev = await _repository.saveThresholds(
        idempotencyKey: _lastThresholdKey!,
        expectedRevision: state.snapshot!.revision,
        changes: changes,
      );

      final newSnapshot = await _repository.load();
      emit(
        state.copyWith(
          status: StockPolicyStatus.ready,
          snapshot: newSnapshot,
          thresholdDrafts: const {},
          savedRevision: rev,
          saving: false,
          clearSaveError: true,
        ),
      );
    } catch (e) {
      final appEx = AppException.from(e);
      final isConflict = appEx.code == InventoryErrorCode.versionConflict ||
          appEx.code == AppErrorCode.stateChanged;

      emit(
        state.copyWith(
          saving: false,
          saveError: appEx,
          lastFailedSave: const FailedThresholdsSave(),
          status: isConflict ? StockPolicyStatus.conflict : state.status,
        ),
      );
    }
  }

  /// Lưu một sản phẩm (dùng trong sheet sửa iPhone hoặc trang một sản phẩm).
  Future<bool> saveSingle(
    String productId,
    String threshold,
    String target,
  ) async {
    if (state.saving || state.readOnly || state.snapshot == null) return false;

    emit(state.copyWith(saving: true, clearSaveError: true));

    final changes = [
      ThresholdChange(
        productId: productId,
        threshold: int.parse(threshold.trim()),
        target: int.parse(target.trim()),
      ),
    ];

    final payload =
        '${changes.first.productId}:${changes.first.threshold}:${changes.first.target}';
    if (_lastSinglePayload != payload || _lastSingleKey == null) {
      _lastSinglePayload = payload;
      _lastSingleKey = _newKey();
    }

    try {
      final rev = await _repository.saveThresholds(
        idempotencyKey: _lastSingleKey!,
        expectedRevision: state.snapshot!.revision,
        changes: changes,
      );

      final newSnapshot = await _repository.load();
      final newDrafts = Map<String, ThresholdDraft>.from(state.thresholdDrafts)
        ..remove(productId);

      emit(
        state.copyWith(
          status: StockPolicyStatus.ready,
          snapshot: newSnapshot,
          thresholdDrafts: newDrafts,
          savedRevision: rev,
          saving: false,
          clearSaveError: true,
        ),
      );
      return true;
    } catch (e) {
      final appEx = AppException.from(e);
      final isConflict = appEx.code == InventoryErrorCode.versionConflict ||
          appEx.code == AppErrorCode.stateChanged;

      emit(
        state.copyWith(
          saving: false,
          saveError: appEx,
          lastFailedSave: FailedSingleSave(
            productId: productId,
            threshold: threshold,
            target: target,
          ),
          status: isConflict ? StockPolicyStatus.conflict : state.status,
        ),
      );
      return false;
    }
  }

  /// Sửa số ngày cận hạn mặc định.
  void editDefaultDays(String days) {
    emit(
      state.copyWith(
        expiryDraft: state.expiryDraft.copyWith(defaultDays: days),
        clearSaveError: true,
      ),
    );
  }

  /// Thêm sản phẩm vào danh sách cận hạn riêng.
  /// Mặc định lấy số ngày đang gõ ở ô mặc định (cap01.js:380).
  void addOverride(String productId) {
    if (state.expiryDraft.overrides.any((o) => o.productId == productId)) {
      return;
    }

    final days = state.expiryDraft.defaultDays;
    final newOverrides = [
      ...state.expiryDraft.overrides,
      ExpiryOverrideDraft(productId: productId, days: days),
    ];

    emit(
      state.copyWith(
        expiryDraft: state.expiryDraft.copyWith(overrides: newOverrides),
        clearSaveError: true,
      ),
    );
  }

  /// Sửa số ngày cận hạn riêng của sản phẩm.
  void editOverrideDays(String productId, String days) {
    final newOverrides = state.expiryDraft.overrides
        .map((o) => o.productId == productId ? o.copyWith(days: days) : o)
        .toList();

    emit(
      state.copyWith(
        expiryDraft: state.expiryDraft.copyWith(overrides: newOverrides),
        clearSaveError: true,
      ),
    );
  }

  /// Xoá sản phẩm khỏi danh sách cận hạn riêng (dùng mặc định).
  void removeOverride(String productId) {
    final newOverrides = state.expiryDraft.overrides
        .where((o) => o.productId != productId)
        .toList();

    emit(
      state.copyWith(
        expiryDraft: state.expiryDraft.copyWith(overrides: newOverrides),
        clearSaveError: true,
      ),
    );
  }

  /// Lưu chính sách cận hạn (mặc định + danh sách riêng).
  Future<void> saveNearExpiry() async {
    if (!state.expiryDirty ||
        state.expiryHasError ||
        state.saving ||
        state.readOnly ||
        state.snapshot == null) {
      return;
    }

    emit(state.copyWith(saving: true, clearSaveError: true));

    final defaultDays = state.expiryDraft.defaultDays.trim().isEmpty
        ? null
        : int.parse(state.expiryDraft.defaultDays.trim());

    final overrides = state.expiryDraft.overrides.map((o) {
      return NearExpiryOverride(
        productId: o.productId,
        days: int.parse(o.days.trim()),
      );
    }).toList();

    final payload =
        '$defaultDays:${overrides.map((o) => '${o.productId}:${o.days}').join(';')}';

    if (_lastExpiryPayload != payload || _lastExpiryKey == null) {
      _lastExpiryPayload = payload;
      _lastExpiryKey = _newKey();
    }

    try {
      final rev = await _repository.saveNearExpiry(
        idempotencyKey: _lastExpiryKey!,
        expectedRevision: state.snapshot!.revision,
        defaultDays: defaultDays,
        overrides: overrides,
      );

      final newSnapshot = await _repository.load();
      final newDefaultDays = newSnapshot.nearExpiryDays?.toString() ?? '';
      final newOverridesDraft = newSnapshot.products
          .where((p) => p.nearExpiryDaysOverride != null)
          .map(
            (p) => ExpiryOverrideDraft(
              productId: p.productId,
              days: p.nearExpiryDaysOverride.toString(),
            ),
          )
          .toList();

      emit(
        state.copyWith(
          status: StockPolicyStatus.ready,
          snapshot: newSnapshot,
          expiryDraft: ExpiryDraft(
            defaultDays: newDefaultDays,
            overrides: newOverridesDraft,
          ),
          savedRevision: rev,
          saving: false,
          clearSaveError: true,
        ),
      );
    } catch (e) {
      final appEx = AppException.from(e);
      final isConflict = appEx.code == InventoryErrorCode.versionConflict ||
          appEx.code == AppErrorCode.stateChanged;

      emit(
        state.copyWith(
          saving: false,
          saveError: appEx,
          lastFailedSave: const FailedNearExpirySave(),
          status: isConflict ? StockPolicyStatus.conflict : state.status,
        ),
      );
    }
  }

  /// Gửi lại lệnh lưu vừa bị lỗi (thresholds / single / nearExpiry).
  Future<void> retryLastSave() async {
    final failed = state.lastFailedSave;
    if (failed == null) return;
    switch (failed) {
      case FailedThresholdsSave():
        await saveThresholds();
      case FailedSingleSave(:final productId, :final threshold, :final target):
        await saveSingle(productId, threshold, target);
      case FailedNearExpirySave():
        await saveNearExpiry();
    }
  }

  /// Đã hiển thị toast xong, xoá savedRevision.
  void consumeSavedRevision() {
    emit(state.copyWith(clearSavedRevision: true));
  }
}

