import '../../../core/di/injection.dart';
import '../../../core/session/session_store.dart';
import '../../iam/data/account_repository.dart';
import 'models/receipt_actor.dart';

Future<ReceiptActor> currentReceiptActor() async {
  final id = getIt<SessionStore>().userId ?? '';
  final account = await getIt<AccountRepository>().getMyAccount();
  return ReceiptActor(id: id, name: account.fullName);
}
