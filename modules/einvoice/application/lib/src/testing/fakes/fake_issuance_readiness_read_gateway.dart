import 'package:vet45_einvoice_domain/domain.dart';

import '../../ports/i_issuance_readiness_read_gateway.dart';

final class FakeIssuanceReadinessReadGateway implements IIssuanceReadinessReadGateway {
  FakeIssuanceReadinessReadGateway({required this.result});

  final IssuanceReadinessInput result;

  @override
  Future<IssuanceReadinessInput> load({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async => result;
}
