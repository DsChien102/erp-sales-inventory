import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../entities/organization_contact.dart';

class OrganizationSinglePrimaryContactRule implements IBusinessRule {
  const OrganizationSinglePrimaryContactRule(this.contacts);

  final List<OrganizationContact> contacts;

  @override
  bool isBroken() => contacts.where((c) => c.isPrimary).length > 1;

  @override
  String get message => 'Organization may have at most one primary contact';
}
