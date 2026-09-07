import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../shared/configuration_readiness_level.dart';

/// Auto-issue enablement requires READY configuration level.
final class AutoIssueRequiresReadyConfigurationRule implements IBusinessRule {
  const AutoIssueRequiresReadyConfigurationRule({
    required this.readinessLevel,
    required this.enablingAutoIssue,
  });

  final ConfigurationReadinessLevel readinessLevel;
  final bool enablingAutoIssue;

  @override
  bool isBroken() => enablingAutoIssue && readinessLevel != ConfigurationReadinessLevel.ready;

  @override
  String get message => 'Configuration is not ready for auto-issue; resolve blockers first';
}
