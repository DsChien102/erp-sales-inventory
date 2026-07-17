final class RuleIssueDto {
  const RuleIssueDto({required this.code, this.field, this.details = const {}});

  final String code;
  final String? field;
  final Map<String, Object?> details;
}
