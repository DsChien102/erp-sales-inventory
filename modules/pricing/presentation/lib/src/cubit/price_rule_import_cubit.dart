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

  /// Bước 1→2: Upload file, nhận preview.
  Future<void> startImport({
    required String fileName,
    required Uint8List fileBytes,
    CustomerPriceRuleImportMode importMode =
        CustomerPriceRuleImportMode.upsert,
  }) async {
    emit(
      PriceRuleImportFileSelected(
        fileName: fileName,
        fileSizeBytes: fileBytes.length,
      ),
    );
    emit(const PriceRuleImportLoading(step: PriceRuleImportStep.preview));

    try {
      final tenantId = await _executionContext.requireTenantId();
      final detail = await _pricingModule.executeCommandAsync(
        StartCustomerPriceRuleImportCommand(
          tenantId: tenantId,
          templateVersion: 'v1',
          originalFileName: fileName,
          fileBytes: fileBytes,
          importMode: importMode,
        ),
      );

      _importId = detail.batch.id;
      _importVersion = detail.batch.version;

      final preview = PriceRuleImportPreview(
        importDetail: detail,
        rows: detail.rows.items,
      );
      _lastPreview = preview;
      emit(preview);
    } on PricingBlockedException catch (e) {
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
    if (current is! PriceRuleImportPreview) return;
    emit(PriceRuleImportConfirm(importDetail: current.importDetail));
  }

  /// Bước 2←: Quay lại chọn file.
  void backToChooseFile() {
    emit(const PriceRuleImportInitial());
    _importId = null;
    _importVersion = null;
    _lastPreview = null;
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

  /// Bước 3→4: Thực hiện import.
  ///
  /// SG-04: businessDate tự lấy ngày hiện tại, không hỏi user.
  Future<void> confirmImport({bool acknowledgeWarningRows = false}) async {
    final id = _importId;
    final version = _importVersion;
    if (id == null || version == null) return;

    emit(const PriceRuleImportLoading(step: PriceRuleImportStep.result));

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

      emit(PriceRuleImportResult(result: result));
    } on PricingBlockedException catch (e) {
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

  void acknowledgeWarnings(bool value) {
    final current = state;
    if (current is! PriceRuleImportConfirm) return;
    emit(
      PriceRuleImportConfirm(
        importDetail: current.importDetail,
        acknowledgeWarningRows: value,
      ),
    );
  }
}
