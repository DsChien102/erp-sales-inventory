/// Result of adding an organization contact link.
final class AddOrganizationContactResult {
  const AddOrganizationContactResult({
    required this.organizationPartnerId,
    required this.personPartnerId,
  });

  final String organizationPartnerId;
  final String personPartnerId;
}
