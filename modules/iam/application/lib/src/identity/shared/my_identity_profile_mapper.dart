import '../../dto/my_account_dto.dart';
import 'my_identity_profile_dto.dart';

MyIdentityProfileDto myIdentityProfileFromAccount(MyAccountDto account) {
  return MyIdentityProfileDto(
    userId: account.userId,
    firstName: account.givenName,
    lastName: account.familyName,
    email: account.email,
    emailVerified: account.emailVerified,
    phoneNumber: account.phone,
    avatarUrl: account.avatarReference,
  );
}
