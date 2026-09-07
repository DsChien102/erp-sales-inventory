import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../support/configuration_query_failure.dart';
import 'einvoice_configuration_overview_state.dart';

final class EInvoiceConfigurationOverviewCubit extends Cubit<EInvoiceConfigurationOverviewState> {
  EInvoiceConfigurationOverviewCubit({
    required IEInvoiceModule einvoiceModule,
    required IExecutionContext executionContext,
  }) : _einvoiceModule = einvoiceModule,
       _executionContext = executionContext,
       super(const EInvoiceConfigurationOverviewInitial());

  final IEInvoiceModule _einvoiceModule;
  final IExecutionContext _executionContext;

  Future<void> load() async {
    emit(const EInvoiceConfigurationOverviewLoading());
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();

      final readiness = await _einvoiceModule.executeQueryAsync(
        GetConfigurationReadinessQuery(tenantId: tenantId, actorId: actorId),
      );
      final screen = await _einvoiceModule.executeQueryAsync(
        GetProviderConnectionScreenQuery(tenantId: tenantId, actorId: actorId),
      );
      final profile = await _einvoiceModule.executeQueryAsync(
        GetIssuanceProfileQuery(tenantId: tenantId, actorId: actorId),
      );
      final templates = screen.connection.status == ProviderConnectionStatus.connected
          ? await _einvoiceModule.executeQueryAsync(
              ListProviderTemplatesQuery(tenantId: tenantId, actorId: actorId),
            )
          : const <ProviderTemplateDto>[];
      final policy = await _einvoiceModule.executeQueryAsync(
        GetAutomationPolicyQuery(tenantId: tenantId, actorId: actorId),
      );

      emit(
        EInvoiceConfigurationOverviewLoaded(
          readiness: readiness,
          connection: screen.connection,
          profile: profile,
          templates: templates,
          policy: policy,
        ),
      );
    } catch (error) {
      emit(EInvoiceConfigurationOverviewError(mapConfigurationQueryFailure(error)));
    }
  }
}
