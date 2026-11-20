import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/features/einvoice/data/einvoice_configuration_repository.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/configuration_query_failure.dart';
import 'package:erp/features/einvoice/logic/einvoice_configuration_overview_state.dart';

final class EInvoiceConfigurationOverviewCubit extends Cubit<EInvoiceConfigurationOverviewState> {
  EInvoiceConfigurationOverviewCubit({
    required EInvoiceConfigurationRepository repository,
  })  : _repository = repository,
        super(const EInvoiceConfigurationOverviewInitial());

  final EInvoiceConfigurationRepository _repository;

  Future<void> load() async {
    emit(const EInvoiceConfigurationOverviewLoading());
    try {
      final readiness = await _repository.getConfigurationReadiness();
      final screen = await _repository.getConnectionScreen();
      final profile = await _repository.getIssuanceProfile();
      final templates = screen.connection.status == ProviderConnectionStatus.connected
          ? await _repository.listTemplates()
          : const <ProviderTemplateDto>[];
      final policy = await _repository.getAutomationPolicy();

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
