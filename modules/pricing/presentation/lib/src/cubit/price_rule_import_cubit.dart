import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'price_rule_import_state.dart';

/// Cubit luồng Import Excel (S8 — SG-04).
///
/// SG-04: Bước 3 (Confirm) không có field "Hiệu lực mặc định cho rule mới".
/// businessDate tự động = ngày hiện tại UTC.
final class PriceRuleImportCubit extends Cubit<PriceRuleImportState> {
  PriceRuleImportCubit({
    required IPricingModule pricingModule,
    required IExecutionContext executionContext,
  }) : _pricingModule = pricingModule,
       _executionContext = executionContext,
       super(const PriceRuleImportInitial());

  final IPricingModule _pricingModule;
  final IExecutionContext _executionContext;

  String? _importId;
  int? _importVersion;
  PriceRuleImportPreview? _lastPreview;
  PriceRuleImportResult? _lastResult;
  PriceRuleImportPendingFile? _pendingFile;
  bool _hasCancelableBatch = false;
  CustomerPriceRuleImportMode _importMode = CustomerPriceRuleImportMode.upsert;

  bool get hasCancelableBatch => _hasCancelableBatch;
  PriceRuleImportPendingFile? get pendingFile => _pendingFile;
  CustomerPriceRuleImportMode get importMode => _importMode;
  String? get currentImportId => _importId;
  List<CustomerPriceRuleImportRowPreviewDto>? get lastPreviewRows =>
      _lastPreview?.rows;

  /// Tải lại toàn bộ dòng (sau confirm) để xuất log `.xlsx`.
  Future<List<CustomerPriceRuleImportRowPreviewDto>> loadRowsForImportLog() async {
    final id = _importId;
    if (id == null) return lastPreviewRows ?? const [];
    try {
      final tenantId = await _executionContext.requireTenantId();
      final detail = await _pricingModule.executeQueryAsync(
        GetCustomerPriceRuleImportQuery(
          tenantId: tenantId,
          importId: id,
          limit: 5000,
        ),
      );
      return detail.rows.items;
    } catch (_) {
      return lastPreviewRows ?? const [];
    }
  }

  /// SC-07: Probe quyền import khi mở màn (qua template query).
  Future<void> checkAccess() async {
    emit(
      const PriceRuleImportLoading(
        step: PriceRuleImportStep.chooseFile,
        message: 'Đang kiểm tra quyền...',
      ),
    );
    try {
      await loadTemplate();
      emit(const PriceRuleImportInitial());
    } on PricingBlockedException catch (e) {
      if (e.code == PricingBlockedCodes.noPermission) {
        emit(const PriceRuleImportNoPermission());
        return;
      }
      emit(const PriceRuleImportInitial());
    } catch (_) {
      emit(const PriceRuleImportInitial());
    }
  }

  Future<CustomerPriceRuleImportTemplateDto> loadTemplate() async {
    final tenantId = await _executionContext.requireTenantId();
    return _pricingModule.executeQueryAsync(
      GetCustomerPriceRuleImportTemplateQuery(tenantId: tenantId),
    );
  }

  /// D-01: Chỉ giữ file — chưa upload.
  void selectFile({
    required String fileName,
    required Uint8List fileBytes,
  }) {
    _pendingFile = PriceRuleImportPendingFile(
      fileName: fileName,
      fileBytes: fileBytes,
    );
    emit(
      PriceRuleImportFileSelected(
        fileName: fileName,
        fileSizeBytes: fileBytes.length,
      ),
    );
  }

  void clearSelectedFile() {
    _pendingFile = null;
    if (state is PriceRuleImportFileSelected ||
        state is PriceRuleImportError) {
      emit(const PriceRuleImportInitial());
    }
  }

  /// D-01 CTA Tiếp tục → upload + preview.
  Future<void> continueWithSelectedFile({
    CustomerPriceRuleImportMode? importMode,
  }) async {
    final pending = _pendingFile;
    if (pending == null) return;
    await startImport(
      fileName: pending.fileName,
      fileBytes: pending.fileBytes,
      importMode: importMode ?? _importMode,
    );
  }

  /// Bước 3: Đổi mode trùng rule — giữ màn confirm + VLoading overlay.
  Future<void> setImportMode(CustomerPriceRuleImportMode mode) async {
    final current = state;
    if (current is! PriceRuleImportConfirm) return;
    if (current.isRefreshingMode) return;
    if (mode == _importMode) return;

    final acknowledged = current.acknowledgeWarningRows;
    _importMode = mode;
    emit(
      PriceRuleImportConfirm(
        importDetail: current.importDetail,
        acknowledgeWarningRows: acknowledged,
        isRefreshingMode: true,
      ),
    );

    await _cancelBatchKeepingPendingFile();

    final pending = _pendingFile;
    if (pending == null) {
      emit(const PriceRuleImportInitial());
      return;
    }

    try {
      final tenantId = await _executionContext.requireTenantId();
      final detail = await _pricingModule.executeCommandAsync(
        StartCustomerPriceRuleImportCommand(
          tenantId: tenantId,
          templateVersion: CustomerPriceRuleImportTemplateDto.versionV1,
          originalFileName: pending.fileName,
          fileBytes: pending.fileBytes,
          importMode: mode,
        ),
      );

      _importId = detail.batch.id;
      _importVersion = detail.batch.version;
      _importMode = detail.batch.importMode;

      if (detail.batch.status == CustomerPriceRuleImportStatus.failed) {
        _hasCancelableBatch = false;
        emit(
          PriceRuleImportError(
            code:
                detail.batch.fileErrorCodes.firstOrNull ??
                'IMPORT_FILE_INVALID',
            step: PriceRuleImportStep.chooseFile,
          ),
        );
        return;
      }

      final preview = PriceRuleImportPreview(
        importDetail: detail,
        rows: detail.rows.items,
      );
      _lastPreview = preview;
      _hasCancelableBatch =
          detail.batch.status == CustomerPriceRuleImportStatus.readyToImport;

      emit(
        PriceRuleImportConfirm(
          importDetail: detail,
          acknowledgeWarningRows:
              acknowledged && detail.batch.warningRows > 0,
          isRefreshingMode: false,
        ),
      );
    } on PricingBlockedException catch (e) {
      if (e.code == PricingBlockedCodes.noPermission) {
        emit(const PriceRuleImportNoPermission());
        return;
      }
      emit(
        PriceRuleImportError(
          code: e.code,
          step: PriceRuleImportStep.confirm,
        ),
      );
    } catch (_) {
      emit(
        const PriceRuleImportError(
          code: 'SYSTEM_ERROR',
          step: PriceRuleImportStep.confirm,
        ),
      );
    }
  }

  /// Bước 1→2: Upload file, nhận preview.
  Future<void> startImport({
    required String fileName,
    required Uint8List fileBytes,
    CustomerPriceRuleImportMode importMode = CustomerPriceRuleImportMode.upsert,
  }) async {
    _importMode = importMode;
    _importId = null;
    _importVersion = null;
    _lastPreview = null;
    _lastResult = null;
    _hasCancelableBatch = false;
    _pendingFile = PriceRuleImportPendingFile(
      fileName: fileName,
      fileBytes: fileBytes,
    );
    emit(
      PriceRuleImportFileSelected(
        fileName: fileName,
        fileSizeBytes: fileBytes.length,
      ),
    );
    emit(
      const PriceRuleImportLoading(
        step: PriceRuleImportStep.preview,
        message: 'Đang kiểm tra dữ liệu...',
      ),
    );

    try {
      final tenantId = await _executionContext.requireTenantId();
      final detail = await _pricingModule.executeCommandAsync(
        StartCustomerPriceRuleImportCommand(
          tenantId: tenantId,
          templateVersion: CustomerPriceRuleImportTemplateDto.versionV1,
          originalFileName: fileName,
          fileBytes: fileBytes,
          importMode: importMode,
        ),
      );

      _importId = detail.batch.id;
      _importVersion = detail.batch.version;
      _importMode = detail.batch.importMode;

      if (detail.batch.status == CustomerPriceRuleImportStatus.failed) {
        _hasCancelableBatch = false;
        emit(
          PriceRuleImportError(
            code:
                detail.batch.fileErrorCodes.firstOrNull ??
                'IMPORT_FILE_INVALID',
            step: PriceRuleImportStep.chooseFile,
          ),
        );
        return;
      }

      final preview = PriceRuleImportPreview(
        importDetail: detail,
        rows: detail.rows.items,
      );
      _lastPreview = preview;
      _hasCancelableBatch =
          detail.batch.status == CustomerPriceRuleImportStatus.readyToImport;
      emit(preview);
    } on PricingBlockedException catch (e) {
      if (e.code == PricingBlockedCodes.noPermission) {
        emit(const PriceRuleImportNoPermission());
        return;
      }
      emit(
        PriceRuleImportError(
          code: e.code,
          step: PriceRuleImportStep.chooseFile,
        ),
      );
    } catch (_) {
      emit(
        const PriceRuleImportError(
          code: 'SYSTEM_ERROR',
          step: PriceRuleImportStep.chooseFile,
        ),
      );
    }
  }

  /// Bước 2→3: Chuyển sang xác nhận.
  void proceedToConfirm() {
    final current = state;
    if (current is! PriceRuleImportPreview || current.readOnly) return;
    emit(PriceRuleImportConfirm(importDetail: current.importDetail));
  }

  /// Bước 2←: Quay lại chọn file.
  void backToChooseFile() {
    _resetImport(keepPendingFile: true);
  }

  /// Bước 3←2: Quay lại xem trước (giữ nguyên dữ liệu đã kiểm tra).
  void backToPreview() {
    final preview = _lastPreview;
    if (preview == null) {
      backToChooseFile();
      return;
    }
    emit(preview);
  }

  /// D-05: Mở lại preview (read-only) từ màn kết quả.
  void reopenPreviewFromResult({
    PriceRuleImportPreviewTab tab = PriceRuleImportPreviewTab.valid,
  }) {
    final preview = _lastPreview;
    if (preview == null) return;
    emit(
      PriceRuleImportPreview(
        importDetail: preview.importDetail,
        rows: preview.rows,
        readOnly: true,
        initialTab: tab,
      ),
    );
  }

  /// Từ preview read-only quay lại kết quả.
  void backToResult() {
    final result = _lastResult;
    if (result == null) {
      backToChooseFile();
      return;
    }
    emit(result);
  }

  /// Bước 3→4: Thực hiện import.
  ///
  /// SG-04: businessDate tự lấy ngày hiện tại, không hỏi user.
  Future<void> confirmImport({bool acknowledgeWarningRows = false}) async {
    final id = _importId;
    final version = _importVersion;
    if (id == null || version == null) return;

    emit(
      const PriceRuleImportLoading(
        step: PriceRuleImportStep.result,
        message: 'Đang nhập dữ liệu...',
      ),
    );

    try {
      final tenantId = await _executionContext.requireTenantId();
      final result = await _pricingModule.executeCommandAsync(
        ConfirmCustomerPriceRuleImportCommand(
          tenantId: tenantId,
          importId: id,
          expectedVersion: version,
          businessDate: DateTime.now().toUtc(), // SG-04: tự động, không hỏi
          acknowledgeWarningRows: acknowledgeWarningRows,
        ),
      );

      _hasCancelableBatch = false;
      final resultState = PriceRuleImportResult(result: result);
      _lastResult = resultState;
      emit(resultState);
    } on PricingBlockedException catch (e) {
      if (e.code == PricingBlockedCodes.noPermission) {
        emit(const PriceRuleImportNoPermission());
        return;
      }
      emit(
        PriceRuleImportError(code: e.code, step: PriceRuleImportStep.confirm),
      );
    } catch (_) {
      emit(
        const PriceRuleImportError(
          code: 'SYSTEM_ERROR',
          step: PriceRuleImportStep.confirm,
        ),
      );
    }
  }

  void acknowledgeWarnings(bool value) {
    final current = state;
    if (current is! PriceRuleImportConfirm || current.isRefreshingMode) {
      return;
    }
    emit(
      PriceRuleImportConfirm(
        importDetail: current.importDetail,
        acknowledgeWarningRows: value,
        isRefreshingMode: false,
      ),
    );
  }

  Future<String?> cancelCurrentImport() async {
    final id = _importId;
    final version = _importVersion;
    if (!_hasCancelableBatch || id == null || version == null) return null;

    try {
      final tenantId = await _executionContext.requireTenantId();
      await _pricingModule.executeCommandAsync(
        CancelCustomerPriceRuleImportCommand(
          tenantId: tenantId,
          importId: id,
          expectedVersion: version,
        ),
      );
      _resetImport(keepPendingFile: false);
      return null;
    } on PricingBlockedException catch (e) {
      return e.code;
    } catch (_) {
      return 'SYSTEM_ERROR';
    }
  }

  /// Hủy batch hiện tại nhưng giữ file đã chọn (đổi importMode).
  Future<void> _cancelBatchKeepingPendingFile() async {
    final id = _importId;
    final version = _importVersion;
    if (!_hasCancelableBatch || id == null || version == null) {
      _importId = null;
      _importVersion = null;
      _lastPreview = null;
      _hasCancelableBatch = false;
      return;
    }

    try {
      final tenantId = await _executionContext.requireTenantId();
      await _pricingModule.executeCommandAsync(
        CancelCustomerPriceRuleImportCommand(
          tenantId: tenantId,
          importId: id,
          expectedVersion: version,
        ),
      );
    } catch (_) {
      // Vẫn tiếp tục start lại; batch cũ có thể orphan đến khi expire.
    }
    _importId = null;
    _importVersion = null;
    _lastPreview = null;
    _hasCancelableBatch = false;
  }

  void _resetImport({required bool keepPendingFile}) {
    _importId = null;
    _importVersion = null;
    _lastPreview = null;
    _lastResult = null;
    _hasCancelableBatch = false;
    if (!keepPendingFile) {
      _pendingFile = null;
      emit(const PriceRuleImportInitial());
      return;
    }
    final pending = _pendingFile;
    if (pending == null) {
      emit(const PriceRuleImportInitial());
      return;
    }
    emit(
      PriceRuleImportFileSelected(
        fileName: pending.fileName,
        fileSizeBytes: pending.fileSizeBytes,
      ),
    );
  }
}
