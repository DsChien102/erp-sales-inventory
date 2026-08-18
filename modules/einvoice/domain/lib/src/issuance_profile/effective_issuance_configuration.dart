import 'package:equatable/equatable.dart';

import 'signing_method.dart';
import 'provider_template_ref.dart';
import 'signing_configuration_ref.dart';

/// Compatible template + signing combo used for issuance readiness.
final class EffectiveIssuanceConfiguration extends Equatable {
  const EffectiveIssuanceConfiguration({
    required this.template,
    required this.signing,
  });

  final ProviderTemplateRef template;
  final SigningConfigurationRef signing;

  /// Returns compatibility warnings (non-blocking) or throws via broken rules.
  List<String> compatibilityWarnings() {
    final warnings = <String>[];
    if (!template.isAvailable) {
      warnings.add('template_unavailable');
    }
    if (!signing.isAvailable) {
      warnings.add('signing_unavailable');
    }
    return warnings;
  }

  /// Whether template + signing combination is valid for persistence.
  bool isCompatible() {
    if (!template.isAvailable || !signing.isAvailable) {
      return false;
    }
    if (signing.method == SigningMethod.noSign && !template.isMtt) {
      return false;
    }
    if (signing.method == SigningMethod.hsm && template.isMtt) {
      return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [template, signing];
}
