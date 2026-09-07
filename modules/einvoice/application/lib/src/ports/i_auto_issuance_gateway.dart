import '../issuance/commands/reevaluate_auto_issuance/auto_issuance_reevaluation_request.dart';
import '../issuance/commands/start_auto_issuance/auto_issuance_start_request.dart';
import '../issuance/commands/start_auto_issuance/start_auto_issuance_result.dart';
import '../issuance/shared/open_auto_issuance_process_dto.dart';

abstract interface class IAutoIssuanceGateway {
  Future<AutoIssuanceResultDto> start(AutoIssuanceStartRequest request);

  Future<AutoIssuanceResultDto> reevaluate(
    AutoIssuanceReevaluationRequest request,
  );

  Future<List<OpenAutoIssuanceProcessDto>> listOpenProcesses({
    required String tenantId,
    required String partnerId,
  });
}
