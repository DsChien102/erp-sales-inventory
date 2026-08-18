import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_automation_policy_gateway.dart';
import 'automation_policy_dto.dart';
import 'get_automation_policy_query.dart';

@QueryHandlerFor(GetAutomationPolicyQuery)
final class GetAutomationPolicyQueryHandler
    implements IQueryHandler<GetAutomationPolicyQuery, AutomationPolicyDto> {
  GetAutomationPolicyQueryHandler({
    required IAutomationPolicyGateway policyGateway,
  }) : _policyGateway = policyGateway;

  final IAutomationPolicyGateway _policyGateway;

  @override
  Future<AutomationPolicyDto> handle(GetAutomationPolicyQuery query) {
    return _policyGateway.getPolicy(
      tenantId: query.tenantId,
      actorId: query.actorId,
    );
  }
}
