import 'package:vet45_shared_application/application.dart';

@PublicAccess()
final class SignInPlatformAdminCommand extends CommandBase<void>
    implements ICommand<void> {
  SignInPlatformAdminCommand({
    String? id,
    required this.email,
    required this.password,
  }) : super(id);

  final String email;
  final String password;
}
