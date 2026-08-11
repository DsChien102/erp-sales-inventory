import 'package:vet45_shared_application/application.dart';

import '../../shared/password_reset_request_result_dto.dart';

@PublicAccess()
final class RequestPasswordResetByEmailCommand
    extends CommandBase<PasswordResetRequestResultDto>
    implements ICommand<PasswordResetRequestResultDto> {
  RequestPasswordResetByEmailCommand({
    String? id,
    required this.email,
  }) : super(id);

  final String email;
}
