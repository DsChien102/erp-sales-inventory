import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'signing_method.dart';
import 'issuance_profile_id.dart';
import '../provider_connection/provider_connection_id.dart';
import '../shared/rules/predicate_business_rule.dart';
import 'rules/template_signing_must_be_compatible_rule.dart';
import 'effective_issuance_configuration.dart';
import 'provider_template_ref.dart';
import 'signing_configuration_ref.dart';

/// IssuanceProfile aggregate — default template + signing per tenant.
final class IssuanceProfile extends Entity<IssuanceProfileId> implements IAggregateRoot {
  IssuanceProfile._({
    required super.id,
    required TenantId tenantId,
    required ProviderConnectionId connectionId,
    EffectiveIssuanceConfiguration? defaultConfiguration,
    required int profileVersion,
    List<String> compatibilityWarnings = const [],
  }) : _tenantId = tenantId,
       _connectionId = connectionId,
       _defaultConfiguration = defaultConfiguration,
       _profileVersion = profileVersion,
       _compatibilityWarnings = List.of(compatibilityWarnings);

  final TenantId _tenantId;
  final ProviderConnectionId _connectionId;
  EffectiveIssuanceConfiguration? _defaultConfiguration;
  int _profileVersion;
  final List<String> _compatibilityWarnings;

  TenantId get tenantId => _tenantId;
  ProviderConnectionId get connectionId => _connectionId;
  EffectiveIssuanceConfiguration? get defaultConfiguration => _defaultConfiguration;
  int get profileVersion => _profileVersion;
  List<String> get compatibilityWarnings => List.unmodifiable(_compatibilityWarnings);

  factory IssuanceProfile.reconstitute({
    required IssuanceProfileId id,
    required TenantId tenantId,
    required ProviderConnectionId connectionId,
    EffectiveIssuanceConfiguration? defaultConfiguration,
    required int profileVersion,
    List<String> compatibilityWarnings = const [],
  }) {
    return IssuanceProfile._(
      id: id,
      tenantId: tenantId,
      connectionId: connectionId,
      defaultConfiguration: defaultConfiguration,
      profileVersion: profileVersion,
      compatibilityWarnings: compatibilityWarnings,
    );
  }

  void setDefault({
    required ProviderTemplateRef template,
    required SigningConfigurationRef signing,
    int? expectedProfileVersion,
  }) {
    assertExpectedVersion(expectedProfileVersion);
    final configuration = EffectiveIssuanceConfiguration(
      template: template,
      signing: signing,
    );
    checkRule(TemplateSigningMustBeCompatibleRule(configuration: configuration));
    _defaultConfiguration = configuration;
    _compatibilityWarnings
      ..clear()
      ..addAll(configuration.compatibilityWarnings());
    _profileVersion += 1;
  }

  void assertExpectedVersion(int? expectedVersion) {
    if (expectedVersion == null) {
      return;
    }
    checkRule(
      PredicateBusinessRule(
        predicate: expectedVersion != _profileVersion,
        ruleMessage:
            'Profile version mismatch: expected $expectedVersion, '
            'actual $_profileVersion',
      ),
    );
  }

  SigningMethod? get signingMethod => _defaultConfiguration?.signing.method;
}
