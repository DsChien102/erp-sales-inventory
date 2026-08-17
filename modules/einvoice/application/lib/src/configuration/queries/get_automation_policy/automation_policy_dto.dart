final class AutomationPolicyDto {
  const AutomationPolicyDto({
    required this.autoIssueEnabled, required this.autoSendEnabled, required this.policyVersion, required this.blockers,
  });

  final bool autoIssueEnabled;
  final bool autoSendEnabled;
  final int policyVersion;
  final List<String> blockers;
}
