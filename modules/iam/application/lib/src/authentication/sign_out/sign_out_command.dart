import 'package:vet45_shared_application/application.dart';

@PublicAccess()
final class SignOutCommand extends CommandBase<void> {
  SignOutCommand({String? id}) : super(id);
}
