import 'package:vet45_shared_application/application.dart';

import '../../../dto/password_reset_request_result_dto.dart';

@PublicAccess()
final class RequestMyPasswordResetCommand
    extends CommandBase<PasswordResetRequestResultDto>
    implements ICommand<PasswordResetRequestResultDto> {
  RequestMyPasswordResetCommand({String? id}) : super(id);
}
