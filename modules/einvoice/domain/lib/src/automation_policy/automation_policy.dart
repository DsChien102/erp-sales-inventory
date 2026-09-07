import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'automation_policy_id.dart';
import '../shared/configuration_readiness_level.dart';
import 'rules/auto_issue_requires_ready_configuration_rule.dart';
import '../shared/rules/predicate_business_rule.dart';

/// AutomationPolicy aggregate — auto-issue / auto-send flags per tenant.
final class AutomationPolicy extends Entity<AutomationPolicyId> implements IAggregateRoot {
  AutomationPolicy._({
    required super.id,
    required TenantId tenantId,
    required bool autoIssueEnabled,
    required bool autoSendEnabled,
    required int policyVersion,
    List<String> blockers = const [],
  }) : _tenantId = tenantId,
       _autoIssueEnabled = autoIssueEnabled,
       _autoSendEnabled = autoSendEnabled,
       _policyVersion = policyVersion,
       _blockers = List.of(blockers);

  final TenantId _tenantId;
  bool _autoIssueEnabled;
  bool _autoSendEnabled;
  int _policyVersion;
  final List<String> _blockers;

  TenantId get tenantId => _tenantId;
  bool get autoIssueEnabled => _autoIssueEnabled;
  bool get autoSendEnabled => _autoSendEnabled;
  int get policyVersion => _policyVersion;
  List<String> get blockers => List.unmodifiable(_blockers);

  factory AutomationPolicy.reconstitute({
    required AutomationPolicyId id,
    required TenantId tenantId,
    required bool autoIssueEnabled,
    required bool autoSendEnabled,
    required int policyVersion,
    List<String> blockers = const [],
  }) {
    return AutomationPolicy._(
      id: id,
      tenantId: tenantId,
      autoIssueEnabled: autoIssueEnabled,
      autoSendEnabled: autoSendEnabled,
      policyVersion: policyVersion,
      blockers: blockers,
    );
  }

  void update({
    bool? autoIssueEnabled,
    bool? autoSendEnabled,
    required int expectedPolicyVersion,
    ConfigurationReadinessLevel readinessForAutoIssue = ConfigurationReadinessLevel.ready,
    bool providerSupportsEmail = true,
  }) {
    assertExpectedVersion(expectedPolicyVersion);
    final enablingAutoIssue = autoIssueEnabled == true && !_autoIssueEnabled;
    if (enablingAutoIssue) {
      checkRule(
        AutoIssueRequiresReadyConfigurationRule(
          readinessLevel: readinessForAutoIssue,
          enablingAutoIssue: true,
        ),
      );
    }
    if (autoSendEnabled == true && !providerSupportsEmail && !_autoSendEnabled) {
      checkRule(
        PredicateBusinessRule(
          predicate: !providerSupportsEmail,
          ruleMessage: 'Provider does not support email delivery for auto-send',
        ),
      );
    }
    if (autoIssueEnabled != null) {
      _autoIssueEnabled = autoIssueEnabled;
    }
    if (autoSendEnabled != null) {
      _autoSendEnabled = autoSendEnabled;
    }
    _blockers.clear();
    if (_autoIssueEnabled && readinessForAutoIssue != ConfigurationReadinessLevel.ready) {
      _blockers.add('config_not_ready_for_auto_issue');
    }
    if (_autoSendEnabled && !providerSupportsEmail) {
      _blockers.add('delivery_not_supported');
    }
    _policyVersion += 1;
  }

  void assertExpectedVersion(int expectedVersion) {
    checkRule(
      PredicateBusinessRule(
        predicate: expectedVersion != _policyVersion,
        ruleMessage:
            'Policy version mismatch: expected $expectedVersion, '
            'actual $_policyVersion',
      ),
    );
  }
}
