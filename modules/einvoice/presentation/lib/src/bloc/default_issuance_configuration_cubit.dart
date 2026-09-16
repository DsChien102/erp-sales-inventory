import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../support/configuration_query_failure.dart';
import '../support/default_issuance_configuration_copy.dart';
import '../support/einvoice_configuration_display.dart';
import 'default_issuance_configuration_state.dart';

enum DefaultIssuanceSaveResult {
  saved,
  validationFailed,
  incompatible,
  notConnected,
  failed,
}

final class DefaultIssuanceConfigurationCubit extends Cubit<DefaultIssuanceConfigurationState> {
  DefaultIssuanceConfigurationCubit({
    required IEInvoiceModule einvoiceModule,
    required IExecutionContext executionContext,
  }) : _einvoiceModule = einvoiceModule,
       _executionContext = executionContext,
       super(const DefaultIssuanceConfigurationInitial());

  final IEInvoiceModule _einvoiceModule;
  final IExecutionContext _executionContext;

  Future<void> load() async {
    emit(const DefaultIssuanceConfigurationLoading());
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final profile = await _einvoiceModule.executeQueryAsync(
        GetIssuanceProfileQuery(tenantId: tenantId, actorId: actorId),
      );
      final templates = await _einvoiceModule.executeQueryAsync(
        ListProviderTemplatesQuery(tenantId: tenantId, actorId: actorId),
      );
      if (isClosed) {
        return;
      }
      emit(
        DefaultIssuanceConfigurationLoaded(
          profile: profile,
          templates: templates,
          selectedTemplateId: profile.templateId,
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
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final signingConfigId = current.selectedTemplate?.isMtt == true
          ? EInvoiceConfigurationDisplay.mttSigningConfigId
          : EInvoiceConfigurationDisplay.fallbackSigningConfigId;
      final profile = await _einvoiceModule.executeCommandAsync(
        SetDefaultIssuanceConfigurationCommand(
          tenantId: tenantId,
          actorId: actorId,
          templateId: templateId,
          signingConfigId: signingConfigId,
          expectedProfileVersion: current.profile.profileVersion,
        ),
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
    } on ProviderNotConnectedException {
      _emitIdle(current);
      return DefaultIssuanceSaveResult.notConnected;
    } on ValidationException {
      _emitIdle(current);
      return DefaultIssuanceSaveResult.incompatible;
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
