import 'package:vet45_shared_application/application.dart';

/// Records required permission codes in tests.
final class FakePermissionChecker implements IPermissionChecker {
  FakePermissionChecker({this.deny = const {}});

  final Set<String> deny;
  final List<String> required = [];

  @override
  Future<void> require(String permissionCode) async {
    required.add(permissionCode);
    if (deny.contains(permissionCode)) {
      throw ApplicationException('Permission denied: $permissionCode');
    }
  }
}
