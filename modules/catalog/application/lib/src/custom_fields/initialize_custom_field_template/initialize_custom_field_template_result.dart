/// Result of initializing custom field template (EPIC-03/US-01/FR-01).
final class InitializeCustomFieldTemplateResult {
  const InitializeCustomFieldTemplateResult({
    required this.groupsCreated,
    required this.fieldsCreated,
    required this.skippedCount,
  });

  final int groupsCreated;
  final int fieldsCreated;
  final int skippedCount;
}
