import 'package:vet45_shared_application/application.dart';

import '../../../dto/password_reset_request_result_dto.dart';

@PublicAccess()
final class ResendMyPasswordResetCommand
    extends CommandBase<PasswordResetRequestResultDto>
    implements ICommand<PasswordResetRequestResultDto> {
  ResendMyPasswordResetCommand({
    String? id,
    required this.operationId,
  }) : super(id);

  final String operationId;
}
