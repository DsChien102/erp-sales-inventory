import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../configuration/shared/readiness_blocker_dto.dart';
import '../../../configuration/shared/readiness_warning_dto.dart';
import '../../../ports/i_issuance_readiness_read_gateway.dart';
import 'get_issuance_readiness_query.dart';
import 'issuance_readiness_dto.dart';

@QueryHandlerFor(GetIssuanceReadinessQuery)
final class GetIssuanceReadinessQueryHandler
    implements IQueryHandler<GetIssuanceReadinessQuery, IssuanceReadinessDto> {
  GetIssuanceReadinessQueryHandler({
    required IIssuanceReadinessReadGateway readinessGateway,
  }) : _readinessGateway = readinessGateway;

  final IIssuanceReadinessReadGateway _readinessGateway;

  @override
  Future<IssuanceReadinessDto> handle(GetIssuanceReadinessQuery query) async {
    final input = await _readinessGateway.load(
      tenantId: query.tenantId,
      actorId: query.actorId,
      salesOrderId: query.salesOrderId,
    );
    final evaluation = IssuanceReadinessEvaluator.evaluate(input);

    return IssuanceReadinessDto(
      level: evaluation.level,
      blockers: evaluation.blockers
          .map((b) => ReadinessBlockerDto(code: b.code, message: b.message))
          .toList(growable: false),
      warnings: evaluation.warnings
          .map((w) => ReadinessWarningDto(code: w.code, message: w.message))
          .toList(growable: false),
      buyerCompletionState: evaluation.buyerCompletionState,
    );
  }
}
