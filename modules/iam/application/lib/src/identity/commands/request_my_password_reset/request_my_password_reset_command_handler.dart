import 'package:vet45_shared_application/application.dart';

import '../../ports/i_identity_self_service_gateway.dart';
import '../../shared/password_reset_operation_dto.dart';
import 'request_my_password_reset_command.dart';

@CommandHandlerFor(RequestMyPasswordResetCommand)
final class RequestMyPasswordResetCommandHandler
    implements
        ICommandHandler<RequestMyPasswordResetCommand, PasswordResetOperationDto> {
  RequestMyPasswordResetCommandHandler({
    required IIdentitySelfServiceGateway identityGateway,
  }) : _identityGateway = identityGateway;

  final IIdentitySelfServiceGateway _identityGateway;

  @override
  Future<PasswordResetOperationDto> handle(
    RequestMyPasswordResetCommand command,
  ) {
    return _identityGateway.requestMyPasswordReset();
  }
}
