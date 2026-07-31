import 'package:vet45_shared_application/application.dart';

import '../../dto/sign_out_result_dto.dart';

@PublicAccess()
final class SignOutCommand extends CommandBase<SignOutResultDto>
    implements ICommand<SignOutResultDto> {
  SignOutCommand({String? id}) : super(id);
}
