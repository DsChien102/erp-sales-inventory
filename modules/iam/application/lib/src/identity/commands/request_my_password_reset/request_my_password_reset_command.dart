import 'package:vet45_shared_application/application.dart';

import '../../shared/password_reset_operation_dto.dart';

@PublicAccess()
final class RequestMyPasswordResetCommand
    extends CommandBase<PasswordResetOperationDto>
    implements ICommand<PasswordResetOperationDto> {
  RequestMyPasswordResetCommand({String? id}) : super(id);
}
