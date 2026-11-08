import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/einvoice/data/einvoice_configuration_repository.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/logic/configuration_query_failure.dart';
import 'package:erp/features/einvoice/logic/default_issuance_configuration_copy.dart';
import 'package:erp/features/einvoice/logic/default_issuance_configuration_state.dart';
import 'package:erp/features/einvoice/logic/einvoice_configuration_display.dart';

enum DefaultIssuanceSaveResult {
  saved,
  validationFailed,
  incompatible,
  notConnected,
  failed,
}

final class DefaultIssuanceConfigurationCubit extends Cubit<DefaultIssuanceConfigurationState> {
  DefaultIssuanceConfigurationCubit({
    required EInvoiceConfigurationRepository repository,
  })  : _repository = repository,
        super(const DefaultIssuanceConfigurationInitial());

  final EInvoiceConfigurationRepository _repository;

  Future<void> load() async {
    emit(const DefaultIssuanceConfigurationLoading());
    try {
      final profile = await _repository.getIssuanceProfile();
      final templates = await _repository.listTemplates();
      final lastSyncedAt = await _readLastSyncedAt();
      if (isClosed) {
        return;
      }
      emit(
        DefaultIssuanceConfigurationLoaded(
          profile: profile,
          templates: templates,
          selectedTemplateId: profile.templateId,
          lastSyncedAt: lastSyncedAt,
        ),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }
      emit(
        DefaultIssuanceConfigurationError(mapConfigurationQueryFailure(error)),
      );
    }
  }

  /// KI-01: sync time comes from the connection (`last_verified_at`);
  /// any failure just hides the line.
  Future<DateTime?> _readLastSyncedAt() async {
    try {
      return (await _repository.getConnectionScreen()).connection.lastCheckedAt;
    } catch (_) {
      return null;
    }
  }

  void selectTemplate(String? templateId) {
    final current = state;
    if (current is! DefaultIssuanceConfigurationLoaded) {
      return;
    }
    emit(
      current.copyWith(
        selectedTemplateId: templateId,
        clearTemplateError: true,
      ),
    );
  }

  Future<DefaultIssuanceSaveResult> save() async {
    final current = state;
    if (current is! DefaultIssuanceConfigurationLoaded) {
      return DefaultIssuanceSaveResult.failed;
    }
    final templateId = current.selectedTemplateId;
    if (templateId == null || templateId.isEmpty) {
      emit(
        current.copyWith(
          templateError: DefaultIssuanceConfigurationCopy.templateRequired,
          clearTemplateError: true,
        ),
      );
      return DefaultIssuanceSaveResult.validationFailed;
    }

    emit(current.copyWith(isSubmitting: true, clearTemplateError: true));
    try {
      final signingConfigId = current.selectedTemplate?.isMtt == true
          ? EInvoiceConfigurationDisplay.mttSigningConfigId
          : EInvoiceConfigurationDisplay.fallbackSigningConfigId;
      final profile = await _repository.setDefaultConfiguration(
        templateId: templateId,
        signingConfigId: signingConfigId,
        expectedProfileVersion: current.profile.profileVersion,
      );
      if (isClosed) {
        return DefaultIssuanceSaveResult.failed;
      }
      emit(
        current.copyWith(
          isSubmitting: false,
          profile: profile,
          selectedTemplateId: profile.templateId ?? templateId,
        ),
      );
      return DefaultIssuanceSaveResult.saved;
    } on AppException catch (e) {
      _emitIdle(current);
      if (e.code == EInvoiceErrorCodes.providerNotConnected) {
        return DefaultIssuanceSaveResult.notConnected;
      }
      if (e.code == EInvoiceErrorCodes.templateNotAvailable ||
          e.code == EInvoiceErrorCodes.signingConfigurationNotAvailable ||
          e.code == EInvoiceErrorCodes.validationError) {
        return DefaultIssuanceSaveResult.incompatible;
      }
      return DefaultIssuanceSaveResult.failed;
    } catch (_) {
      _emitIdle(current);
      return DefaultIssuanceSaveResult.failed;
    }
  }

  void _emitIdle(DefaultIssuanceConfigurationLoaded current) {
    if (isClosed) {
      return;
    }
    emit(current.copyWith(isSubmitting: false));
  }
}
